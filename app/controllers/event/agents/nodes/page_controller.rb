class Event::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::ForMemberFilter::Node
  include Event::EventHelper
  helper Event::EventHelper
  helper Event::IcalHelper
  helper Map::EventHelper

  before_action :set_display, only: [:index, :monthly]

  def index
    @date = Time.zone.today.beginning_of_month
    @year = @date.year
    @month = @date.month
    raise '404' if !within_one_year?(@date) && !within_one_year?(@date.advance(months: 1, days: -1))

    index_monthly
  end

  def monthly
    @year = params[:year].to_i
    @month = params[:month].to_i
    @date = Date.new(@year, @month, 1) rescue nil
    raise '404' if @date.nil?
    raise '404' if !within_one_year?(@date) && !within_one_year?(@date.advance(months: 1, days: -1))

    index_monthly
  end

  def daily
    @year  = params[:year].to_i
    @month = params[:month].to_i
    @day   = params[:day].to_i
    @date  = Date.new(@year, @month, @day) rescue nil
    raise '404' if @date.nil?
    raise '404' if !within_one_year?(@date)

    index_daily
  end

  private

  def pages
    Cms::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end

  def set_display
    @cur_display = @cur_node.event_display
    if params[:display].present? && params[:display] != "index"
      @cur_display = params[:display]
    end
    raise "404" if !@cur_node.event_display_tabs.include?(@cur_display)
  end

  def index_monthly
    @items = pages.where('event_dates.0' => { "$exists" => true })

    disp_cur_display = I18n.t("event.options.event_display.#{@cur_display || "table"}")
    if params[:year].present?
      @cur_node.window_name = "#{@cur_node.name} #{disp_cur_display} #{I18n.l(@date, format: :long_month)}"
    else
      @cur_node.window_name = "#{@cur_node.name} #{disp_cur_display}"
    end

    respond_to do |format|
      format.html do
        case @cur_display
        when "list"
          index_monthly_list
        when "table"
          index_monthly_table
        when "map"
          index_monthly_map
        end
      end
      format.ics do
        index_monthly_ics
      end
    end
  end

  def index_monthly_list
    start_date = @date
    close_date = start_date.advance(months: 1)
    set_events(start_date...close_date)
    render :monthly_list
  end

  def index_monthly_table
    start_date = @date.advance(days: -1 * @date.wday)
    close_date = start_date.advance(days: 7 * 6)
    set_events(start_date...close_date)
    render :monthly_table
  end

  def index_monthly_map
    start_date = @date
    close_date = start_date.advance(months: 1)
    set_markers(start_date...close_date)
    render :monthly_map
  end

  def index_monthly_ics
    if params[:year].present?
      start_date = @date
      close_date = @date.advance(months: 1)
    else
      start_date = @date.advance(days: - SS.config.event.ical_export_date_ago).beginning_of_month
      close_date = @date.advance(days: SS.config.event.ical_export_date_after).end_of_month
    end
    dates = (start_date..close_date).map { |d| d.mongoize }
    @items = @items.where(:event_dates.in => dates)
    render :index
  end

  def index_daily
    @items = pages.where(event_dates: @date)

    respond_to do |format|
      format.html do
        index_daily_events
      end
      format.ics do
        render :daily
      end
    end
  end

  def index_daily_events
    node_category_ids = @cur_node.st_categories.pluck(:id)
    @events = events([@date.mongoize]).map do |page|
      [
        page,
        page.categories.in(id: node_category_ids).and_public(@cur_date).order_by(order: 1)
      ]
    end

    @cur_node.window_name ||= "#{@cur_node.name} #{I18n.l(@date, format: :long)}"

    render :daily
  end

  def events(date)
    @items.where(:event_dates.in => date).
      entries.
      sort_by { |page| page.event_dates.size }
  end

  def set_events(dates)
    @events = {}
    dates.each do |d|
      @events[d] = []
    end
    dates = dates.map { |m| m.mongoize }
    node_category_ids = @cur_node.st_categories.pluck(:id)
    events(dates).each do |page|
      page.event_dates.each do |d|
        next unless @events[d]
        @events[d] << [
          page,
          page.categories.in(id: node_category_ids).and_public(@cur_date).order_by(order: 1)
        ]
      end
    end
  end

  def set_markers(dates)
    @markers = []
    dates = dates.map { |m| m.mongoize }
    @items = events(dates)
    @items.each do |item|
      next if !item.respond_to?(:map_points)
      next if item.map_points.blank?

      item.map_points.each do |map_point|
        map_point[:html] = view_context.render_marker_info(item, map_point)
        @markers << map_point
      end
    end
  end
end
