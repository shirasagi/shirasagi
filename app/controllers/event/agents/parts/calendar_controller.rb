class Event::Agents::Parts::CalendarController < ApplicationController
  include Cms::PartFilter::View
  helper Event::EventHelper

  before_action :set_year_month

  def index
    @current_month_date = Date.new(@year, @month, 1)
    @prev_month_date = @current_month_date.change(day: 1).advance(days: -1)
    @next_month_date = @current_month_date.advance(months: 1)
    @dates = []

    start_date = @current_month_date.advance(days: -1 * @current_month_date.wday)
    close_date = start_date.advance(days: 7 * 6)
    dates = (start_date...close_date).to_a

    set_event_dates(dates.collect(&:mongoize))
    dates.each do |d|
      @dates.push [ d, @event_dates.include?(d) ]
    end

    if preview_path?
      @render_url = cms_preview_path(site: @cur_site, preview_date: params[:preview_date], path: @cur_part.url[1..-1])
    else
      @render_url = @cur_part.url
    end
  end

  private

  def set_year_month
    y = params[:year]
    m = params[:month]

    if y.present? && m.present? && Date.valid_date?(y.to_i, m.to_i, 1)
      @year = y.to_i
      @month = m.to_i
      @day = Time.zone.today.day.to_i
    elsif cur_page.blank?
      @cur_main_path.sub(/\..+?$/, "").scan(/(\d{4})(\d{2})(\d{2})?$/).each do |y, m, d|
        d = 1 unless d
        if Date.valid_date?(y.to_i, m.to_i, d.to_i)
          @year = y.to_i
          @month = m.to_i
          @day = d.to_i
        end
      end
    end

    if @year.blank? || @month.blank?
      @year  = Time.zone.today.year.to_i
      @month = Time.zone.today.month.to_i
      @day = Time.zone.today.day.to_i
    end
  end

  def set_event_dates(dates)
    @event_dates = Cms::Page.public_list(
        site: @cur_site,
        part: @cur_part.parent.try(:becomes_with_route),
        date: @cur_date).
      in(event_dates: dates).
      distinct(:event_dates).
      flatten.compact.uniq.sort
  end
end
