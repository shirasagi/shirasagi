class Facility::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper
  helper Map::MapHelper

  public
    def set_items
      if params[:q].present?
        @category_ids = params[:q][:category_ids].select{ |id| id.present? }.map{ |id| id.to_i }
        @service_ids  = params[:q][:service_ids].select{ |id| id.present? }.map{ |id| id.to_i }
        @location_ids = params[:q][:location_ids].select{ |id| id.present? }.map{ |id| id.to_i }
      end

      q_category = @category_ids.present? ? { category_ids: @category_ids } : {}
      q_service  = @service_ids.present? ? { service_ids: @service_ids } : {}
      q_location = @location_ids.present? ? { location_ids: @location_ids } : {}

      @categories = Facility::Node::Category.in(_id: @category_ids)
      @services   = Facility::Node::Service.in(_id: @service_ids)
      @locations  = Facility::Node::Location.in(_id: @location_ids)

      @items = Facility::Node::Page.site(@cur_site).public.
        where(@cur_node.condition_hash).
        in(q_category).
        in(q_service).
        in(q_location).
        order_by(name: 1)
    end

    def index
    end

    def map
      set_items

      @markers = []
      @items.each do |item|
        category_ids = item.categories.pluck(:_id)
        image_ids    = item.categories.pluck(:image_id)
        image_url    = SS::File.find(image_ids.first).url rescue nil
        marker_info  = view_context.render_marker_info(item)

        maps = Facility::Map.site(@cur_site).public.
          where(filename: /^#{item.filename}\//, depth: item.depth + 1).order_by(order: 1)

        maps.each do |map|
          map.map_points.each do |point|
            point[:html] = marker_info
            point[:category] = category_ids
            point[:image] = image_url if image_url.present?
            @markers.push point
          end
        end
      end
    end

    def result
      set_items
      @items = @items.page(params[:page]).
        per(@cur_node.limit)
    end
end
