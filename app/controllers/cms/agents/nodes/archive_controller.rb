class Cms::Agents::Nodes::ArchiveController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::ForMemberFilter::Node
  helper Cms::ListHelper
  helper Cms::ArchiveHelper
  helper Event::EventHelper

  before_action :set_range, only: [:yearly, :monthly, :daily]

  prepend_view_path "app/views/cms/agents/nodes/archive"

  private

  def set_range
    ymd = params[:ymd].presence
    case ymd.length
    when 4
      # year is specified
      @year = ymd.to_i
      from = Time.zone.local(ymd.to_i, 1, 1)
      to = from + 1.year - 1.second
      @range = from..to
    when 6
      # year/month is specified
      @year = ymd[0..3].to_i
      @month = ymd[4..5].to_i
      from = Time.zone.local(@year, @month, 1)
      to = from + 1.month - 1.second
      @range = from..to
    when 8
      # year/month/day is specified
      @year = ymd[0..3].to_i
      @month = ymd[4..5].to_i
      @day = ymd[6..7].to_i
      from = Time.zone.local(@year, @month, @day)
      to = from + 1.day - 1.second
      @range = from..to
    end
  rescue
    raise SS::NotFoundError
  end

  def condition_hash
    @condition_hash ||= begin
      parent = @cur_node.parent
      condition_hash = @cur_node.condition_hash
      if @cur_node.conditions.blank? && parent && parent.respond_to?(:condition_hash)
        condition_hash = parent.condition_hash
      end
      condition_hash
    end
  end

  def pages
    Cms::Page.site(@cur_site).and_public(@cur_date).where(condition_hash)
  end

  def set_list_items
    @items = pages.
      where(released: @range).
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)
  end

  def set_calendar_items
    @items = {}
    start_date = Date.new(@year, @month, 1)
    close_date = start_date.end_of_month
    (start_date..close_date).each do |date|
      beginning_of_day = date.in_time_zone.beginning_of_day
      end_of_day = date.in_time_zone.end_of_day

      monthly_pages = pages.and([
        { released: { "$gte" => beginning_of_day } },
        { released: { "$lte" => end_of_day } },
      ]).to_a
      @items[date] = monthly_pages
    end
  end

  def set_navi_years
    @years = pages.pluck(:released).sort.reverse.map do |released|
      released.year
    end.uniq
  end

  def set_navi_months
    @months = pages.pluck(:released).sort.reverse.map do |released|
      [released.year, released.month]
    end.uniq
  end

  def render_with_pagination(items, template: nil)
    raise SS::NotFoundError if params[:page].to_i > 1 && items.empty?
    template ||= params[:action]
    render template: template
  end

  public

  def yearly
    set_list_items
    set_navi_years
    render_with_pagination(@items, template: "yearly_list")
  end

  def monthly
    if @cur_node.archive_view == 'calendar'
      set_calendar_items
      render template: 'monthly_calendar'
    else
      set_list_items
      set_navi_months
      render_with_pagination(@items, template: "monthly_list")
    end
  end

  def daily
    set_list_items
    render_with_pagination(@items, template: "daily_list")
  end

  def index
    path = (@cur_node.archive_view == 'yearly_list') ? "#{Time.zone.now.strftime('%Y')}/" : "#{Time.zone.now.strftime('%Y%m')}/"
    path = ::File.join(@cur_node.filename, path)
    path = preview_path? ? cms_preview_path(site: @cur_site, path: path) : ::File.join(@cur_site.full_url, path)

    @redirect_link = path
    render html: "", layout: "cms/redirect"
  end
end
