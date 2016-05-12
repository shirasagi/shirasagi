class Facility::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  helper Map::MapHelper
  append_view_path "app/views/facility/agents/addons/search_setting/view"
  append_view_path "app/views/facility/agents/addons/search_result/view"

  private
    def set_query
      @keyword      = params[:keyword]
      @category_ids = params[:category_ids].select(&:present?).map(&:to_i) rescue []
      @service_ids  = params[:service_ids].select(&:present?).map(&:to_i) rescue []
      @location_ids = params[:location_ids].select(&:present?).map(&:to_i) rescue []

      @q_category = @category_ids.present? ? { category_ids: @category_ids } : {}
      @q_service  = @service_ids.present? ? { service_ids: @service_ids } : {}
      @q_location = @location_ids.present? ? { location_ids: @location_ids } : {}

      @categories = Facility::Node::Category.in(_id: @category_ids)
      @services   = Facility::Node::Service.in(_id: @service_ids)
      @locations  = Facility::Node::Location.in(_id: @location_ids)
    end

    def set_items
      @items = Facility::Node::Page.site(@cur_site).and_public.
        where(@cur_node.condition_hash).
        search(name: @keyword).
        in(@q_category).
        in(@q_service).
        in(@q_location).
        order_by(name: 1)
    end

    def set_markers
      @items = []
      @markers = []
      images = SS::File.all.map {|image| [image.id, image.url]}.to_h

      Facility::Map.site(@cur_site).and_public.each do |map|
        parent_path = ::File.dirname(map.filename)
        item = Facility::Node::Page.site(@cur_site).and_public.
          where(@cur_node.condition_hash).
          in_path(parent_path).
          search(name: @keyword).
          in(@q_category).
          in(@q_service).
          in(@q_location).first

        next unless item

        @items << item
        categories   = item.categories.entries
        category_ids = categories.map(&:id)
        image_id     = categories.map(&:image_id).first

        image_url = images[image_id]
        marker_info = view_context.render_marker_info(item)

        map.map_points.each do |point|
          point[:id] = item.id
          point[:html] = marker_info
          point[:category] = category_ids
          point[:image] = image_url if image_url.present?
          @markers.push point
        end
      end

      @items.sort_by!(&:name)
    end

    def set_filter_items
      @filter_categories = @cur_node.st_categories.in(_id: @items.map(&:category_ids).flatten)
      @filter_locations = @cur_node.st_locations.entries.select{ |l| l.center_point[:loc].present? }
      @focus_options = @filter_locations.map do |l|
        opts = {}
        opts["data-zoom-level"] = l.center_point[:zoom_level] if l.center_point[:zoom_level]
        [l.name, l.center_point[:loc].join(","), opts]
      end
      @focus_options.unshift [I18n.t("facility.select_location"), ""]
    end

  public
    def index
      set_query
      render :index, locals: { search_path: "./map.html" }
    end

    def map
      set_query
      set_markers
      set_filter_items
      @current = "map"
      render :map
    end

    def result
      set_query
      set_items
      @current = "result"
      @items = @items.page(params[:page]).
        per(@cur_node.limit)
      render :result
    end

    def map_all
      params[:category_ids] = nil
      params[:service_ids]  = nil
      params[:location_ids] = nil
      map
    end
end
