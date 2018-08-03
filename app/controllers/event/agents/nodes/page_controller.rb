class Event::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::ForMemberFilter::Node
  include Event::EventHelper
  helper Event::EventHelper
  helper Event::IcalHelper

  def index
    @year  = Time.zone.today.year.to_i
    @month = Time.zone.today.month.to_i
    @cur_node.window_name = @cur_node.name
    @index = true

    @items = Cms::Page.site(@cur_site).and_public(@cur_date).
      where(@cur_node.condition_hash).
      where('event_dates.0' => { "$exists" => true })

    monthly
  end

  def monthly
    @year  = params[:year].to_i if @year.blank?
    @month = params[:month].to_i if @month.blank?
    @date  = Date.new(@year, @month, 1)
    @cur_node.window_name ||= "#{@cur_node.name} #{I18n.l(@date, format: :long_month)}"

    if within_one_year?(@date) || within_one_year?(@date.advance(months: 1, days: -1))
      return index_monthly if params[:display].to_s.start_with?('list')
      return index_monthly_table if params[:display].to_s.start_with?('table') || @cur_node.event_display.to_s.start_with?('table')
      index_monthly
    else
      raise "404"
    end
  end

  def daily
    @year  = params[:year].to_i
    @month = params[:month].to_i
    @day   = params[:day].to_i
    @date  = Date.new(@year, @month, @day)
    @cur_node.window_name ||= "#{@cur_node.name} #{I18n.l(@date, format: :long)}"

    if within_one_year?(@date)
      index_daily
    else
      raise "404"
    end
  end

  private

  def events(date)
    events = Cms::Page.site(@cur_site).and_public(@cur_date).
      where(@cur_node.condition_hash).
      where(:event_dates.in => date).
      entries.
      sort_by{ |page| page.event_dates.size }
  end

  def index_monthly
    if @cur_node.event_display == 'table_only'
      raise '404'
    end
    @events = {}
    @items = [] unless @index
    start_date = Date.new(@year, @month, 1)
    close_date = @month != 12 ? Date.new(@year, @month + 1, 1) : Date.new(@year + 1, 1, 1)

    (start_date...close_date).each do |d|
      @events[d] = []
    end

    dates = (start_date...close_date).map { |m| m.mongoize }
    events(dates).each do |page|
      page.event_dates.split(/\r\n|\n/).each do |date|
        d = Date.parse(date)
        next unless @events[d]
        @items << page unless @index
        @events[d] << [
          page,
          page.categories.in(id: @cur_node.st_categories.pluck(:id)).order_by(order: 1)
        ]
      end
    end
    @items.uniq! unless @index

    render :monthly
  end

  def index_monthly_table
    if @cur_node.event_display == 'list_only'
      raise '404'
    end
    @events = {}
    @items = [] unless @index
    start_date = @date.advance(days: -1 * @date.wday)
    close_date = start_date.advance(days: 7 * 6)

    (start_date...close_date).each do |d|
      @events[d] = []
    end

    dates = (start_date...close_date).map { |m| m.mongoize }
    events(dates).each do |page|
      page.event_dates.split(/\R/).each do |date|
        d = Date.parse(date)
        next unless @events[d]
        @items << page unless @index
        @events[d] << [
          page,
          page.categories.in(id: @cur_node.st_categories.pluck(:id)).order_by(order: 1)
        ]
      end
    end
    @items.uniq! unless @index

    render :monthly_table
  end

  def index_daily
    @date = Date.new(@year, @month, @day)
    @items = []
    @events = events([@date.mongoize]).map do |page|
      @items << page
      [
        page,
        page.categories.in(id: @cur_node.st_categories.pluck(:id)).order_by(order: 1)
      ]
    end
    @items.uniq!

    render :daily
  end
end
