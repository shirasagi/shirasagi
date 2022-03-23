class Cms::SearchContents::FilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::ApiFilter::Contents
  include SS::FileFilter

  model SS::File

  navi_view "cms/search_contents/navi"

  if Rails.env.development?
    before_action { ::Rails.application.eager_load! }
  end

  class << self
    def all_page_models
      @all_page_models ||= ::Mongoid.models.select { |model| model.ancestors.include?(Cms::Model::Page) }.map(&:name)
    end
  end

  private

  def set_crumbs
    @crumbs << [t("cms.file"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    # prepare stages
    stages = []
    stages << { "$match" => { owner_item_type: { "$in" => self.class.all_page_models } } }
    if params[:s].present?
      stages << { "$match" => @model.unscoped.search(params[:s]).selector }
    end
    stages << { "$lookup" => { from: "cms_pages", "localField" => "owner_item_id", "foreignField" => "_id", as: "page" } }
    if @cur_user.cms_role_permissions["read_other_cms_pages_#{@cur_site.id}"]
      stages << { "$match" => { "page.site_id" => @cur_site.id } }
    else
      stages << { "$match" => { "page.site_id" => @cur_site.id, "page.group_ids" => { "$in" => @cur_site.group_ids } } }
    end
    stages << { "$project" => @model.fields.keys.index_with { 1 } }
    # pagination: see https://stackoverflow.com/questions/20348093/mongodb-aggregation-how-to-get-total-records-count
    limit = 50
    page = params[:page].try { |page| page.to_i - 1 } || 0
    offset = page * limit
    stages << {
      "$facet" => {
        "paginatedResults" => [{ "$skip" => offset }, { "$limit" => limit }],
        "totalCount" => [{ "$count" => "count" }]
      }
    }

    # execute aggregation and get result
    result = @model.collection.aggregate(stages)
    items = total_count = nil
    result.first.tap do |data|
      items = data["paginatedResults"]
      items = items.to_a.map { |data| @model.new(data) }

      total_count = data["totalCount"].try { |c| c.first.try { |d| d["count"] } } || 0
    end

    @items = Kaminari.paginate_array(items, limit: limit, offset: offset, total_count: total_count)
  end
end
