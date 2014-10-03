# coding: utf-8
module Opendata::Nodes::Dataset
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    include Opendata::UrlHelper

    public
      def pages
        Opendata::Dataset.site(@cur_site).node(@cur_node).public
      end

      def index
        @count = pages.size
        @search_url = search_datasets_path

        @items = pages.
          order_by(released: -1).
          limit(10)

        @point_items = pages.
          order_by(point: -1).
          limit(10)

        @download_items = pages.
          order_by(downloaded: -1).
          limit(10)

        @tabs = [
          { name: "新着順", url: "#{@search_url}?sort=released", pages: @items },
          { name: "人気順", url: "#{@search_url}?sort=popular", pages: @point_items },
          { name: "注目順", url: "#{@search_url}?sort=attention", pages: @download_items }
        ]

        cond = {
          route: Opendata::Dataset.new.route,
          site_id: @cur_site.id,
          filename: /^#{@cur_node.filename}\//,
          depth: @cur_node.depth + 1,
          state: "public"
        }

        @areas = []
        Opendata::Dataset.total_field(:area_ids, cond).each do |m|
          if item = Opendata::Node::Area.site(@cur_site).public.where(id: m["id"]).first
            item[:count] = m["count"]
            @areas << item
          end
        end

        @tags = Opendata::Dataset.total_field(:tags, cond)
        @formats = Opendata::Dataset.total_field("resources.format", cond)
        @licenses = Opendata::Dataset.total_field(:license, cond)

        render
      end

      def show
        @item = Opendata::Dataset.site(@cur_site).node(@cur_node).public.
          filename(@cur_path).
          first

        render
      end
  end
end
