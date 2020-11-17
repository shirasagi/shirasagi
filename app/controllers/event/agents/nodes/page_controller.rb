class Event::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::ForMemberFilter::Node
  include Event::EventHelper
  helper Event::EventHelper
  helper Event::IcalHelper

  before_action :set_display, only: [:index]
  before_action :set_calendar_year_month, only: [:index]

  def index
    @items = Cms::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date).
      where('event_dates.0' => { "$exists" => true })

    disp_cur_display = I18n.t("event.options.event_display.#{@cur_display || "table"}")
    if @year_presented
      @cur_node.window_name ||= "#{@cur_node.name} #{disp_cur_display} #{I18n.l(@date, format: :long_month)}"
    else
      @cur_node.window_name = "#{@cur_node.name} #{disp_cur_display}"
    end

    respond_to do |format|
      format.html do
        case @cur_display
        when "list"
          index_monthly_list
        else # when "table"
          index_monthly_table
        end
      end
      format.ics do
        index_ics
      end
    end

  end

  def daily
    @year  = params[:year].to_i
    @month = params[:month].to_i
    @day   = params[:day].to_i
    @date  = Date.new(@year, @month, @day)
    raise "404" if !within_one_year?(@date)

    @items = Cms::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date).
      where(event_dates: @date)

    respond_to do |format|
      format.html do
        index_daily
      end
      format.ics do
        render :daily
      end
    end
  end

  private

  def set_display
    default_display = @cur_node.event_display.to_s.start_with?('table') ? 'table' : 'list'
    @cur_display = params[:display].to_s.presence
    @cur_display ||= default_display
    @cur_display = default_display if @cur_display == "index"
    raise '404' if @cur_display != 'list' && @cur_display != 'table'
    raise '404' if @cur_display == 'list' && @cur_node.event_display == 'table_only'
    raise '404' if @cur_display == 'table' && @cur_node.event_display == 'list_only'
  end

  def set_calendar_year_month
    if params[:year].present?
      raise '404' if !params[:year].numeric? || !params[:month].numeric?

      @year_presented = true
      @year = params[:year].to_i
      @month = params[:month].to_i
      @date = Date.new(@year, @month, 1)
    else
      @year_presented = false
      @date = Time.zone.today.beginning_of_month
      @year = @date.year
      @month = @date.month
    end

    raise '404' if !within_one_year?(@date) && !within_one_year?(@date.advance(months: 1, days: -1))
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
      page.event_dates.split(/\R/).each do |date|
        d = Date.parse(date)
        next unless @events[d]
        @events[d] << [
          page,
          page.categories.in(id: node_category_ids).and_public.order_by(order: 1)
        ]
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

  def index_ics
    if @year_presented
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
    node_category_ids = @cur_node.st_categories.pluck(:id)
    @events = events([@date.mongoize]).map do |page|
      [
        page,
        page.categories.in(id: node_category_ids).and_public.order_by(order: 1)
      ]
    end

    @cur_node.window_name ||= "#{@cur_node.name} #{I18n.l(@date, format: :long)}"

    render :daily
  end
end
