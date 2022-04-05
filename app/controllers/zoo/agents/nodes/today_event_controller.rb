# 本日のイベント
class Zoo::Agents::Nodes::TodayEventController < ApplicationController
  include Cms::NodeFilter::View

  helper_method :cur_ymd, :cur_business_day, :each_time_zone, :each_item_within_time, :within_valid_range?

  private

  def cur_ymd
    return @cur_ymd if @cur_ymd

    if params[:ymd].blank?
      @cur_ymd = Time.zone.today
      return @cur_ymd
    end

    ymd = params[:ymd].to_s
    raise "404" if ymd.length != 8 || !ymd.numeric?

    yyyy = ymd[0..3]
    mm = ymd[4..5]
    dd = ymd[6..7]

    @cur_ymd = Time.zone.parse("#{yyyy}/#{mm}/#{dd}").to_date
  end

  def cur_business_day
    return @cur_business_day if @cur_business_day_searched

    @cur_business_day = Zoo::BusinessDay.site(@cur_site).where(date: cur_ymd).first
  ensure
    @cur_business_day_searched = 1
  end

  def pages
    return @pages if @pages

    condition_hash = @cur_node.parent.condition_hash
    @pages = Cms::Page.site(@cur_site).and_public(@cur_date).where(condition_hash).where(event_dates: cur_ymd)
  end

  def each_time_zone
    in_service = cur_business_day.blank? || cur_business_day.state.blank?
    return unless in_service

    service_start_at = Zoo.make_time(cur_ymd, cur_business_day.try(:start_at) || Zoo::BusinessDay::DEFAULT_START_AT)
    service_end_at = Zoo.make_time(cur_ymd, cur_business_day.try(:end_at) || Zoo::BusinessDay::DEFAULT_END_AT)

    service_time_zone_start_at = service_start_at.change(min: 0)
    service_time_zone_end_at = service_end_at.change(min: 0)
    service_time_zone_end_at += 1.hour if service_end_at.min != 0

    time_zone = service_time_zone_start_at
    while time_zone < service_time_zone_end_at
      yield time_zone, time_zone + 1.hour
      time_zone += 1.hour
    end
  end

  def each_item_within_time(start_at, end_at = nil, &block)
    end_at ||= start_at + 1.hour
    @items.select { |item| item.event_within_time?(start_at, end_at) }.each(&block)
  end

  def within_valid_range?(date)
    this_month = Time.zone.today.beginning_of_month
    return false if date < this_month
    return false if date > this_month + Zoo::SERVICE_STATUS_DURATION - 1.day
    true
  end

  public

  def index
    @items = pages.order_by(order: 1).to_a
    render
  end
end
