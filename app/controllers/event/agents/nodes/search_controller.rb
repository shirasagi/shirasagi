class Event::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  include Event::EventHelper
  helper Event::EventHelper
  helper Cms::ListHelper

  before_action :set_params

  def index
    @categories = []
    @items = []
    if @cur_node.parent
      @categories = Cms::Node.site(@cur_site).where({:id.in => @cur_node.parent.st_category_ids}).sort(filename: 1)
    end
    if @keyword.present? || @category_ids.present? || @start_date.present? || @close_date.present? || @facility_ids.present?
      list_events
      set_markers
    end
    @facilities = Facility::Node::Page.site(@cur_site).and_public
  end

  private

  def set_params
    safe_params = params.permit(:search_keyword, :facility_id, category_ids: [], event: [ :start_date, :close_date])
    @keyword = safe_params[:search_keyword].presence
    @category_ids = safe_params[:category_ids].presence || []
    @category_ids = @category_ids.map(&:to_i)
    if params[:event].present? && params[:event][0].present?
      @start_date = params[:event][0][:start_date].presence
      @close_date = params[:event][0][:close_date].presence
    end
    @start_date = Date.parse(@start_date) if @start_date.present?
    @close_date = Date.parse(@close_date) if @close_date.present?
    @facility_id = safe_params[:facility_id].presence
    if @facility_id.present?
      @facility_ids = Facility::Node::Page.site(@cur_site).where(id: @facility_id).and_public.pluck(:id)
    end
  end

  def list_events
    criteria = Cms::Page.site(@cur_site).and_public
    criteria = criteria.search(keyword: @keyword) if @keyword.present?
    criteria = criteria.where(@cur_node.condition_hash)
    criteria = criteria.in(category_ids: @category_ids) if @category_ids.present?
    criteria = criteria.in(facility_ids: @facility_ids) if @facility_id.present?

    if @start_date.present? && @close_date.present?
      criteria = criteria.search(dates: @start_date..@close_date)
    elsif @start_date.present?
      criteria = criteria.search(start_date: @start_date)
    elsif @close_date.present?
      criteria = criteria.search(close_date: @close_date)
    else
      criteria = criteria.exists(event_dates: 1)
    end

    @items = criteria.order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit).to_a

    @items.each do |item|
      if event_end_date(item).present?
        next if event_end_date(item) >= Time.zone.today
        @items.delete(item)
      end
    end
  end

  def set_markers
    @markers = []
    @items = list_events
    @items.each do |item|
      event = Event::Page.site(@cur_site).
        and_public.
        where(filename: item.filename).first

      if event.map_points.present?
        event.map_points.each do |map_point|
          marker_info = view_context.render_map_point_info(event, map_point)
          map_point[:html] = marker_info
          @markers << map_point
        end
      end

      if event.map_points.blank? && event.facility_ids.present?
        event.facility_ids.each do |facility_id|
          if @facility_ids.present?
            next if !@facility_ids.include?(facility_id)
          end
          facility = Facility::Node::Page.site(@cur_site).and_public.where(id: facility_id).first
          items = Facility::Map.site(@cur_site).and_public.
            where(filename: /^#{::Regexp.escape(facility.filename)}\//, depth: facility.depth + 1).order_by(order: 1).first.map_points
          items.each do |item|
            marker_info = view_context.render_facility_info(facility)
            item[:html] = marker_info
            @markers << item
          end
        end
      end
    end
  end

  def event_end_date(event)
    event_dates = event.get_event_dates
    return if event_dates.blank?

    event_range = event_dates.first

    if event_dates.length == 1
      end_date = ::Icalendar::Values::Date.new(event_range.last.tomorrow.to_date)
    else # event_dates.length > 1
      dates = event_dates.flatten.uniq.sort
      event_range = ::Icalendar::Values::Array.new(dates, ::Icalendar::Values::Date, {}, { delimiter: "," })
      end_date = ::Icalendar::Values::Date.new(event_range.last.tomorrow.to_date)
    end
    end_date
  end
end
