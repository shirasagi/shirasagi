class SS::SortEmulator
  extend Forwardable
  include Enumerable

  BATCH_SIZE = 100

  attr_reader :criteria, :sort_hash

  def initialize(criteria, sort_hash)
    @criteria = criteria
    @sort_hash = sort_hash

    if @criteria.is_a?(Mongoid::Document)
      # this means "all"
      @model_class = @criteria
      @selector = @criteria.all.selector
    else
      @model_class = @criteria.klass
      @selector = @criteria.selector
    end
  end

  def_delegators :@criteria, :count, :exists?

  def length
    @criteria.count
  end

  def empty?
    !@criteria.exists?
  end

  def each(&block)
    if able_to_sort_by_ruby?
      generic_ruby_sort(&block)
    else
      mongo_sort(&block)
    end
  end

  private

  def able_to_sort_by_ruby?
    return false if sort_hash.keys.length != 1

    key = sort_hash.keys.first
    key = key.to_s unless key.is_a?(String)
    return false if key.include?(".") || key.include?("$")

    true
  end

  def _ruby_sort(all_id_with_values, &block)
    if @criteria.options.present? && @criteria.options.limit.present?
      all_id_with_values = all_id_with_values.take(@criteria.options.limit)
    end

    all_id_with_values.each_slice(BATCH_SIZE) do |id_with_values|
      ids = id_with_values.map { |id, *_val| id }
      items = @model_class.unscoped.in(id: ids).to_a
      items.sort_by! { |item| ids.index(item.id) }
      items.each(&block)
    end
  end

  def generic_ruby_sort(&block)
    if length > 0
      all_id_with_values = @model_class.all.where(@selector).reorder(id: 1).pluck(:id, *sort_hash.keys)
    else
      all_id_with_values = []
    end
    all_id_with_values.sort! { |lhs, rhs| page_id_sort_proc(lhs, rhs) }

    _ruby_sort(all_id_with_values, &block)
  end

  def mongo_sort(&block)
    all_ids = @criteria.order_by(sort_hash).pluck(:id)
    all_ids.each_slice(BATCH_SIZE) do |ids|
      items = @model_class.unscoped.in(id: ids).to_a
      items.sort_by! { |item| ids.index(item.id) }
      items.each(&block)
    end
  end

  def normalize_sort_direction(direction)
    case direction
    when 1, "1", "asc"
      1
    when -1, "-1", "desc"
      -1
    else
      1
    end
  end

  def compare_value_asc(lhs_val, rhs_val)
    if lhs_val.nil?
      if rhs_val.nil?
        0
      else
        # put nil first
        -1
      end
    elsif rhs_val.nil?
      # put nil first
      1
    else
      lhs_val <=> rhs_val
    end
  end

  def page_id_sort_proc(lhs, rhs)
    cmp = 0

    sort_hash.each_with_index do |sort, index|
      _field, direction = *sort
      lhs_val = lhs[index + 1]
      rhs_val = rhs[index + 1]

      if normalize_sort_direction(direction) > 0
        cmp = compare_value_asc(lhs_val, rhs_val)
      else
        cmp = compare_value_asc(rhs_val, lhs_val)
      end

      break if cmp != 0
    end

    if cmp == 0
      # fallback: compare ids
      cmp = compare_value_asc(lhs[0], rhs[0])
    end

    cmp
  end
end
