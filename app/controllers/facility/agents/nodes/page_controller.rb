class Facility::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  public
    def map_pages
      Facility::Map.site(@cur_site).public.
        where(filename: /^#{@cur_node.filename}\//, depth: @cur_node.depth + 1).order_by(order: -1)
    end

    def image_pages
      Facility::Image.site(@cur_site).public.
        where(filename: /^#{@cur_node.filename}\//, depth: @cur_node.depth + 1).order_by(order: -1)
    end

    def index
      map_pages.each do |map|

        points = []
        map.map_points.each_with_index do |point, i|
          points.push point

          image_ids = @cur_node.categories.pluck(:image_id)
          points[i][:pointer_image] = SS::File.find(image_ids.first).url if image_ids.present?
        end
        map.map_points = points

        if @merged_map
          @merged_map.map_points += map.map_points
        else
          @merged_map = map
        end
      end

      @summary_image = nil
      @images = []
      image_pages.each do |page|
        next if page.image.blank?

        if @summary_image
          @images.push page
        else
          @summary_image = page
        end
      end
    end
end
