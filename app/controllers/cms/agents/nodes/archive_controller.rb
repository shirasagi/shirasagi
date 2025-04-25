class Cms::Agents::Nodes::ArchiveController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::ForMemberFilter::Node
  helper Cms::ListHelper
  helper Cms::ArchiveHelper
  helper Event::EventHelper

  before_action :set_range, only: :index
  before_action :set_cur_parent

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
      @range_type = "yearly"
    when 6
      # year/month is specified
      @year = ymd[0..3].to_i
      @month = ymd[4..5].to_i
      from = Time.zone.local(@year, @month, 1)
      to = from + 1.month - 1.second
      @range = from..to
      @range_type = "monthly"
    when 8
      # year/month/day is specified
      @year = ymd[0..3].to_i
      @month = ymd[4..5].to_i
      day = ymd[6..7].to_i
      from = Time.zone.local(@year, @month, day)
      to = from + 1.day - 1.second
      @range = from..to
      @range_type = "daily"
    else
      raise SS::NotFoundError
    end
  rescue
    raise SS::NotFoundError
  end

  def set_cur_parent
    @cur_parent = @cur_node.parent
  end

  def pages
    if @cur_node.conditions.present?
      condition_hash = @cur_node.condition_hash
    else
      condition_hash = @cur_parent.try(:condition_hash)
      condition_hash ||= @cur_node.condition_hash
    end

    Cms::Page.site(@cur_site).and_public(@cur_date).where(condition_hash).where(released: @range)
  end

  public

  def index
    if @cur_node.archive_view == 'calendar' && @range_type == "monthly"
      index_calendar
    else
      index_list
    end
  end

  def index_list
    @items = pages.
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination @items
  end

  def index_calendar
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

    render template: 'calendar'
  end

  def redirect_to_archive_index
    archive_path = "#{@cur_main_path[1..-1].sub('/index.html', '')}/#{Time.zone.now.strftime('%Y%m')}/"
    render_url = "#{@cur_site.full_url}#{archive_path}"

    if preview_path?
      render_url = "#{cms_preview_path(site: @cur_site, path: @cur_main_path[1..-1].sub('/index.html', ''))}/#{Time.zone.now.strftime('%Y%m')}/"
    end

    redirect_to render_url
  end

  # def rss
  #   @items = pages.
  #     order_by(publushed: -1).
  #     per(@cur_node.limit)
  #
  #   render_rss @cur_node, @items
  # end
end
