# coding: utf-8
module Facility::Nodes::Search
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    helper Cms::ListHelper

    public
      def set_items
        category_ids = params[:q][:category_ids].select{ |id| id.present? }.map{ |id| id.to_i }
        use_ids      = params[:q][:use_ids].select{ |id| id.present? }.map{ |id| id.to_i }
        location_ids = params[:q][:location_ids].select{ |id| id.present? }.map{ |id| id.to_i }

        q_category = category_ids.present? ? { category_ids: category_ids } : {}
        q_use      = use_ids.present? ? { use_ids: use_ids } : {}
        q_location = location_ids.present? ? { location_ids: location_ids } : {}

        @categories = Facility::Node::Category.in(_id: category_ids)
        @uses       = Facility::Node::Use.in(_id: use_ids)
        @locations  = Facility::Node::Location.in(_id: location_ids)

        @items = Facility::Node::Page.site(@cur_site).public.
          in(q_category).
          in(q_use).
          in(q_location).
          order_by(name: 1)
      end

      def index
        render
      end

      def map
        set_items

        @markers = []
        @map_loc  = []
        @map_zoom = nil

        @items.each do |item|
          Facility::Map.site(@cur_site).public.
            where(filename: /^#{item.filename}\//, depth: item.depth + 1).order_by(order: -1).each do |map|
              points = []
              map.map_points.each do |point|
                point[:info] = render(file: "_marker_info", locals: {item: item})
                point[:location] = item.locations.pluck(:_id)

                image_ids = item.categories.pluck(:image_id)
                point[:pointer_image] = SS::File.find(image_ids.first).url if image_ids.present?

                points.push point
              end
              @markers += points

              @map_loc = map.map_loc if @map_loc.blank?
              @map_zoom = map.map_zoom if @map_zoom.blank?
          end
        end

        @map_loc =  [ 35.392915, 139.442888 ] if @map_loc.blank?
        @map_zoom = 5 if @map_zoom.blank?

        render
      end

      def result
        set_items
        @items = @items.page(params[:page]).
          per(@cur_node.limit)

        render
      end
  end
end
