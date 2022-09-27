class Cms::FileSearchService
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :keyword, :page, :limit

  STAGE_BUILDERS = %i[
    stage_files_attached_to_page stage_lookup_pages stage_search stage_permissions stage_projection stage_pagination
  ].freeze

  class << self
    def page_models
      @page_models ||= ::Mongoid.models.select { |model| model.ancestors.include?(Cms::Model::Page) }.map(&:name)
    end
  end

  def initialize(*args)
    super
    @page ||= 0
    @limit ||= 50
  end

  def call
    @stages = []
    STAGE_BUILDERS.each do |builder|
      send(builder)
    end

    # execute aggregation and get result
    results = SS::File.collection.aggregate(@stages)
    return [] if results.blank?

    result = results.first
    return [] if result.blank?

    items = parse_results(result)
    return [] if items.blank?

    total_count = parse_total_count(result)
    Kaminari.paginate_array(items, limit: limit, offset: offset, total_count: total_count)
  end

  private

  def offset
    page * limit
  end

  def stage_files_attached_to_page
    @stages << { "$match" => { owner_item_type: { "$in" => self.class.page_models } } }
  end

  def stage_lookup_pages
    @stages << { "$lookup" => { from: "cms_pages", "localField" => "owner_item_id", "foreignField" => "_id", as: "page" } }
  end

  def stage_search
    return if keyword.blank?

    words = keyword.to_s.split(/[\s　]+/).uniq.select(&:present?)
    return if words.blank?

    words = words.take(4).map { |w| /#{::Regexp.escape(w)}/i }
    conds = words.map do |word|
      { "$or" => %w(name filename page.name page.filename).map { |field| { field => word } } }
    end

    if conds.length == 1
      @stages << { "$match" => conds.first }
    else
      @stages << { "$match" => { "$and" => conds } }
    end
  end

  def stage_permissions
    if cur_user.cms_role_permissions["read_other_cms_pages_#{cur_site.id}"]
      @stages << { "$match" => { "page.site_id" => cur_site.id } }
    else
      @stages << { "$match" => { "page.site_id" => cur_site.id, "page.group_ids" => { "$in" => cur_site.group_ids } } }
    end
  end

  def stage_projection
    @stages << { "$project" => SS::File.fields.keys.index_with { 1 } }
  end

  def stage_pagination
    # pagination: see https://stackoverflow.com/questions/20348093/mongodb-aggregation-how-to-get-total-records-count
    @stages << {
      "$facet" => {
        "paginatedResults" => [{ "$skip" => offset }, { "$limit" => limit }],
        "totalCount" => [{ "$count" => "count" }]
      }
    }
  end

  def parse_results(data)
    results = data["paginatedResults"]
    return [] if results.blank?

    results.map { |data| SS::File.new(data) }
  end

  def parse_total_count(data)
    total_count_array = data["totalCount"]
    return 0 if total_count_array.blank?

    total_count = total_count_array.first
    return 0 if total_count.blank?

    total_count["count"] || 0
  end
end
