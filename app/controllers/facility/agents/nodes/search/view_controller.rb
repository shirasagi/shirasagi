module Facility::Agents::Nodes::Search
  class ViewController < ApplicationController
    include Cms::NodeFilter::View
    helper Cms::ListHelper

    public
      def set_items
        category_ids = params[:q][:category_ids].select{ |id| id.present? }.map{ |id| id.to_i }
        feature_ids      = params[:q][:feature_ids].select{ |id| id.present? }.map{ |id| id.to_i }
        location_ids = params[:q][:location_ids].select{ |id| id.present? }.map{ |id| id.to_i }

        q_category = category_ids.present? ? { category_ids: category_ids } : {}
        q_feature      = feature_ids.present? ? { feature_ids: feature_ids } : {}
        q_location = location_ids.present? ? { location_ids: location_ids } : {}

        @categories = Facility::Node::Category.in(_id: category_ids)
        @features   = Facility::Node::Feature.in(_id: feature_ids)
        @locations  = Facility::Node::Location.in(_id: location_ids)

        @items = Facility::Node::Page.site(@cur_site).public.
          in(q_category).
          in(q_feature).
          in(q_location).
          order_by(name: 1)
      end

      def index
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
                point[:info] = render_to_string(partial: "marker_info", locals: {item: item})
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
      end

      def result
        set_items
        @items = @items.page(params[:page]).
          per(@cur_node.limit)
      end
  end
end
