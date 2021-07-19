class SS::SortEmulator
  extend Forwardable
  include Enumerable

  attr_reader :criteria, :sort_hash

  def initialize(criteria, sort_hash)
    @criteria = criteria
    @sort_hash = sort_hash
  end

  def_delegators :@criteria, :count, :exists?

  def length
    @criteria.count
  end

  def empty?
    !@criteria.exists?
  end

  def each(&block)
    if sort_hash.keys.length != 1 || sort_hash.keys.first.include?(".") || sort_hash.keys.first.include?("$")
      mongo_sort(&block)
    else
      generic_ruby_sort(&block)
    end
  end

  private

  def generic_ruby_sort(&block)
    @criteria.reorder(id: 1).to_a.sort { |lhs, rhs| page_sort_proc(sort_hash, lhs, rhs) }.each(&block)
  end

  def mongo_sort(&block)
    @criteria.order_by(sort_hash).to_a.each(&block)
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

  def page_sort_proc(sort_hash, lhs, rhs)
    cmp = 0

    sort_hash.each_with_index do |sort, _index|
      field, direction = *sort
      lhs_val = lhs.send(field)
      rhs_val = rhs.send(field)

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
