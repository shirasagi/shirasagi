module Opendata::AppFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_app_with_aggregation, only: [:index_areas, :index_tags, :index_licenses]
  end

  private
    def set_app_with_aggregation
      @cur_node.layout = nil
      @search_path     = method(:search_apps_path)
    end

    def aggregate_areas(limit)
      counts = pages.aggregate_array(:area_ids, limit: limit).map { |c| [c["id"], c["count"]] }.to_h

      areas = []
      Opendata::Node::Area.site(@cur_site).public.order_by(order: 1).map do |item|
        next unless counts[item.id]
        item.count = counts[item.id]
        areas << item
      end
      areas
    end

    def aggregate_tags(limit)
      pages.aggregate_array :tags, limit: limit
    end

    def aggregate_licenses(limit)
      pages.aggregate_field :license, limit: limit
    end

  public
    def index_areas
      @areas = aggregate_areas(100)
      render "opendata/agents/nodes/app/areas", layout: "opendata/app_aggregation"
    end

    def index_tags
      @tags = aggregate_tags(100)
      render "opendata/agents/nodes/app/tags", layout: "opendata/app_aggregation"
    end

    def index_licenses
      @licenses = aggregate_licenses(100)
      render "opendata/agents/nodes/app/licenses", layout: "opendata/app_aggregation"
    end
end
