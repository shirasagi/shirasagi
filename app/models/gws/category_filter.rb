class Gws::CategoryFilter
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :category_model
  attr_writer :categories

  def categories
    return @categories if @categories
    @categories = category_model.all.site(cur_site).readable(cur_user, site: cur_site)
  end

  def base64_filter
    return if blank_filter?(@json)
    ::Base64.urlsafe_encode64(@json.to_json, padding: false)
  end

  def base64_filter=(base64_string)
    if base64_string.blank?
      @json = nil
      @selected_categories = nil
      return
    end

    @json = ::JSON.parse(::Base64.urlsafe_decode64(base64_string)).with_indifferent_access
    @selected_categories = nil
  end

  def to_json(_options = nil)
    @json
  end

  def simple?
    return true unless @json
    @json[:op] == "all" && @json[:filters].blank?
  end

  def advanced?
    !simple?
  end

  def empty?
    blank_filter?(@json)
  end

  def overall_operator_all?
    return true unless @json
    return true if @json[:op].blank?
    return true if @json[:op] == "all"
    false
  end

  def each_filter(&block)
    return unless @json

    filters = @json[:filters]
    if filters
      filters.each_with_index(&block)
    end
  end

  def change(add: nil, delete: nil)
    ret = nil
    if add
      ret ||= copy
      if ret.simple?
        ret.send(:add_to_simple, add)
      else
        # ret.send(:add_to_advanced, add)
        raise "this operation is not supported in advanced mode."
      end
    end

    if delete
      ret ||= copy
      if ret.simple?
        ret.send(:delete_from_simple, delete)
      else
        # ret.send(:delete_from_advanced, delete)
        raise "this operation is not supported in advanced mode."
      end
    end

    ret || self
  end

  def copy
    ret = self.class.new(cur_site: cur_site, cur_user: cur_user, category_model: category_model)
    ret.categories = categories if @categories
    ret.base64_filter = base64_filter if @json
    ret
  end

  def selected_categories
    return @selected_categories if @selected_categories
    return @selected_categories = category_model.none if @json.blank?

    selected_categories = []
    if @json[:categories].present?
      selected_categories += @json[:categories]
    end
    if @json[:filters].present?
      @json[:filters].each do |filter|
        selected_categories += filter[:categories] if filter[:categories].present?
      end
    end

    selected_categories.compact!
    selected_categories.uniq!
    return @selected_categories = category_model.none if selected_categories.blank?

    @selected_categories = categories.in(id: selected_categories)
  end

  def to_mongoid_criteria
    return {} if @json.blank?
    parse_filter(@json)
  end

  private

  def add_to_simple(category_id)
    if @json.blank?
      @json = { op: "all", categories: [ category_id ] }
      return
    end

    unless @json[:categories].include?(category_id)
      @json[:categories].push(category_id)
    end
  end

  def delete_from_simple(category_id)
    return if @json.blank? || @json[:categories].blank?
    @json[:categories].delete(category_id)
  end

  # def add_to_advanced(category_id)
  #   @json[:filters] ||= []
  #   if @json[:filters].any? { |filter| filter[:op] == "all" && filter[:categories].include?(category_id) }
  #     # already included
  #     return
  #   end
  #   @json[:filters] << { op: "all", categories: [ category_id ] }
  # end

  # def delete_from_advanced(category_id)
  #   @json[:categories].delete(category_id) if @json[:categories]
  #   if @json[:filters]
  #     @json[:filters].each do |filter|
  #       filter[:categories].delete(category_id) if filter[:categories]
  #     end
  #     @json[:filters].delete_if { |filter| blank_filter?(filter) }
  #   end
  # end

  def blank_filter?(filter)
    return true if filter.blank?
    %i[categories filters].all? { |key| filter[key].blank? }
  end

  def id_category_map
    @id_category_map ||= categories.to_a.index_by(&:id)
  end

  def parse_filter(filter, depth: 0)
    conditions = []
    if filter[:categories]
      case filter[:op]
      when "any"
        op = "$in"
      when "none"
        op = "$nin"
      else # "all"
        op = "$all"
      end

      category_ids = filter[:categories]
      category_ids = category_ids.select { |id| id_category_map.key?(id) }
      conditions << { category_ids: { op => category_ids } }
    end
    if depth == 0 && filter[:filters]
      conditions += filter[:filters].map { |sub_filter| parse_filter(sub_filter, depth: depth + 1) }
    end
    return conditions.first if conditions.length <= 1

    case filter[:op]
    when "any"
      { "$or" => conditions }
    else # "all"
      { "$and" => conditions }
    end
  end
end
