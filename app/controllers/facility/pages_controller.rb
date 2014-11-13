class Facility::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Facility::Node::Page

  prepend_view_path "app/views/cms/node/nodes"
  menu_view "facility/page/menu"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "facility/page" }
    end

    def map_pages
      Facility::Map.site(@cur_site).public.
        where(filename: /^#{@item.filename}\//, depth: @item.depth + 1).order_by(order: -1)
    end

    def image_pages
      Facility::Image.site(@cur_site).public.
        where(filename: /^#{@item.filename}\//, depth: @item.depth + 1).order_by(order: -1).
        select { |page| page.image.present? }
    end

  public
    def show
      raise "403" unless @item.allowed?(:read, @cur_user)
      action = @cur_node.allowed?(:edit, @cur_user, site: @cur_site) ? :edit : :show

      @maps = map_pages
      @maps.each do |map|
        points = []
        map.map_points.each_with_index do |point, i|
          points.push point

          image_ids = @item.categories.pluck(:image_id)
          points[i][:image] = Facility::TempFile.find(image_ids.first).url if image_ids.present?
        end
        map.map_points = points

        if @merged_map
          @merged_map.map_points += map.map_points
        else
          @merged_map = map
        end
      end

      pages = image_pages.map do |page|
        [
          page,
          send("#{action}_facility_image_path", cid: @item.id, id: page.id ),
          { width: page.image_thumb_width, height: page.image_thumb_height }
        ]
      end
      @summary_image = [ pages.shift ].compact
      @images = pages
    end
end
