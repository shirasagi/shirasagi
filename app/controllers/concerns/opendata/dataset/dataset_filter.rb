module Opendata::Dataset::DatasetFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_dataset_with_aggregation,
      only: [:index_categories, :index_estat_categories, :index_areas, :index_tags, :index_formats, :index_licenses]
  end

  private

  def set_dataset_with_aggregation
    @cur_node.layout = nil
    @search_path     = view_context.method(:search_datasets_path)
  end

  def aggregate_categories(limit)
    counts = pages.aggregate_array(:category_ids, limit: limit)
    @categories_popped = counts.popped?
    counts = counts.map { |c| [c["id"], c["count"]] }.to_h

    categories = []
    Opendata::Node::Category.site(@cur_site).and_public.order_by(order: 1).map do |item|
      next unless counts[item.id]
      item.count = counts[item.id]
      categories << item
    end
    categories.sort_by { |c| -1 * c.count }
  end

  def aggregate_estat_categories(limit)
    counts = pages.aggregate_array(:estat_category_ids, limit: limit)
    @estat_categories_popped = counts.popped?
    counts = counts.map { |c| [c["id"], c["count"]] }.to_h

    estat_categories = []
    Opendata::Node::EstatCategory.site(@cur_site).and_public.order_by(order: 1).map do |item|
      next unless counts[item.id]
      item.count = counts[item.id]
      estat_categories << item
    end
    estat_categories.sort_by { |c| -1 * c.count }
  end

  def aggregate_areas(limit)
    counts = pages.aggregate_array(:area_ids, limit: limit)
    @areas_popped = counts.popped?
    counts = counts.map { |c| [c["id"], c["count"]] }.to_h

    areas = []
    Opendata::Node::Area.site(@cur_site).and_public.order_by(order: 1).map do |item|
      next unless counts[item.id]
      item.count = counts[item.id]
      item.code = item.pref_code ? item.pref_code.code : "000000"
      areas << item
    end
    areas.sort_by { |c| c.code }
  end

  def aggregate_tags(limit)
    pages.aggregate_array :tags, limit: limit
  end

  def aggregate_formats(limit)
    pages.aggregate_resources :format, limit: limit
  end

  def aggregate_licenses(limit)
    licenses = pages.aggregate_resources :license_id, limit: limit

    licenses.each_with_index do |data, idx|
      if rel = Opendata::License.site(@cur_site).and_public.where(id: data["id"]).first
        licenses[idx] = { "id" => rel.id, "name" => rel.name, "count" => data["count"] }
      else
        licenses[idx] = nil
      end
    end
    licenses
  end

  public

  def index_categories
    @categories = aggregate_categories(100)
    render "opendata/agents/nodes/dataset/dataset/categories", layout: "opendata/dataset_aggregation"
  end

  def index_estat_categories
    @estat_categories = aggregate_estat_categories(100)
    render "opendata/agents/nodes/dataset/dataset/estat_categories", layout: "opendata/dataset_aggregation"
  end

  def index_areas
    @areas = aggregate_areas(100)
    render "opendata/agents/nodes/dataset/dataset/areas", layout: "opendata/dataset_aggregation"
  end

  def index_tags
    @tags = aggregate_tags(100)
    render "opendata/agents/nodes/dataset/dataset/tags", layout: "opendata/dataset_aggregation"
  end

  def index_formats
    @formats = aggregate_formats(100)
    render "opendata/agents/nodes/dataset/dataset/formats", layout: "opendata/dataset_aggregation"
  end

  def index_licenses
    @licenses = aggregate_licenses(100)
    render "opendata/agents/nodes/dataset/dataset/licenses", layout: "opendata/dataset_aggregation"
  end
end
