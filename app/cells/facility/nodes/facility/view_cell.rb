# coding: utf-8
module Facility::Nodes::Facility
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    helper Cms::ListHelper

    public
#      def facilities
#        Facility::Node::Facility.site(@cur_site).public.
#          where(@cur_node.condition_hash)
#      end

#      def index
#        @items = facilities.
#          order_by(@cur_node.sort_hash).
#          page(params[:page]).
#          per(@cur_node.limit)
#
#        @items.empty? ? "" : render
#      end

      def map_pages
        Facility::Map.site(@cur_site).public.
          where(filename: /^#{@cur_node.filename}\//, depth: @cur_node.depth + 1)
      end

      def image_pages
        Facility::Image.site(@cur_site).public.
          where(filename: /^#{@cur_node.filename}\//, depth: @cur_node.depth + 1)
      end

      def index
        map_pages.each do |map|
          if @merged_map
            @merged_map.map_points += map.map_points
          else
            @merged_map = map
          end
        end

        @body_images = []
        image_pages.each do |page|
          if @summary_image
            @body_images.push(page.image)
          else
            @summary_image = page.image
          end
        end

        render
      end

#      def rss
#        @items = facilities.
#          order_by(released: -1).
#          limit(@cur_node.limit)
#
#        render_rss @cur_node, @items
#      end
  end
end
