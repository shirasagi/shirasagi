module Opendata::DatasetFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_dataset_with_aggregation,
      only: [:index_areas, :index_tags, :index_formats, :index_licenses]
  end

  private
    def set_dataset_with_aggregation
      @cur_node.layout = nil
      @search_url      = search_datasets_path + "?"
    end

    def aggregate_areas(limit)
      areas = pages.aggregate_array :area_ids, limit: limit
      areas.each_with_index do |data, idx|
        if rel = Opendata::Node::Area.site(@cur_site).public.where(id: data["id"]).first
          areas[idx] = { "id" => rel.id, "name" => rel.name, "count" => data["count"] }
        else
          areas[idx] = nil
        end
      end
      areas
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
        if rel = Opendata::License.site(@cur_site).public.where(id: data["id"]).first
          licenses[idx] = { "id" => rel.id, "name" => rel.name, "count" => data["count"] }
        else
          licenses[idx] = nil
        end
      end
      licenses
    end

  public
    def index_areas
      @areas = aggregate_areas(100)
      render "opendata/agents/nodes/dataset/areas", layout: "opendata/dataset_aggregation"
    end

    def index_tags
      @tags = aggregate_tags(100)
      render "opendata/agents/nodes/dataset/tags", layout: "opendata/dataset_aggregation"
    end

    def index_formats
      @formats = aggregate_formats(100)
      render "opendata/agents/nodes/dataset/formats", layout: "opendata/dataset_aggregation"
    end

    def index_licenses
      @licenses = aggregate_licenses(100)
      render "opendata/agents/nodes/dataset/licenses", layout: "opendata/dataset_aggregation"
    end
end
