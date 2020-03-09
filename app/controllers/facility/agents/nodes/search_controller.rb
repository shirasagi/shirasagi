class Facility::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  helper Map::MapHelper
  append_view_path "app/views/facility/agents/addons/search_setting/view"
  append_view_path "app/views/facility/agents/addons/search_result/view"

  private

  def set_query
    @keyword      = params[:keyword].try { |keyword| keyword.to_s }
    @category_ids = params[:category_ids].select(&:numeric?).map(&:to_i) rescue []
    @service_ids  = params[:service_ids].select(&:numeric?).map(&:to_i) rescue []
    @location_ids = params[:location_ids].select(&:numeric?).map(&:to_i) rescue []

    @q_category = @category_ids.present? ? { category_ids: @category_ids } : {}
    @q_service  = @service_ids.present? ? { service_ids: @service_ids } : {}
    @q_location = @location_ids.present? ? { location_ids: @location_ids } : {}

    @categories = Facility::Node::Category.site(@cur_site).and_public.in(id: @category_ids)
    @services   = Facility::Node::Service.site(@cur_site).and_public.in(id: @service_ids)
    @locations  = Facility::Node::Location.site(@cur_site).and_public.in(id: @location_ids)
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
    @markers = []

    @items.each do |item|
      category_ids, image_ids = item.categories.pluck(:id, :image_id).transpose
      image_id = image_ids.try(:first)
      image_url = SS::File.where(id: image_id).first.try(:url) if image_id.present?
      marker_info = view_context.render_marker_info(item)
      maps = Facility::Map.site(@cur_site).
        and_public.
        where(filename: /\A#{::Regexp.escape(item.filename)}\//, depth: item.depth + 1).
        order_by(order: 1)

      maps.each do |map|
        map.map_points.each do |point|
          point[:id] = item.id
          point[:html] = marker_info
          point[:category] = category_ids
          point[:image] = image_url if image_url.present?
          @markers.push point
        end
      end
    end
  end

  def set_filter_items
    @filter_categories = @cur_node.st_categories.in(id: @items.map(&:category_ids).flatten)
    @filter_locations = @cur_node.st_locations.entries.select{ |l| l.center_point[:loc].present? }
    @focus_options = @filter_locations.map do |l|
      opts = {}
      opts["data-zoom-level"] = l.center_point[:zoom_level] if l.center_point[:zoom_level]
      [l.name, l.center_point[:loc].join(","), opts]
    end
  end

  public

  def index
    set_query
    render :index, locals: { search_path: "#{@cur_node.url}map.html" }
  end

  def map
    set_query
    set_items
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
