class Cms::Agents::Parts::CalendarNavController < ApplicationController
  include Cms::PartFilter::View
  helper Event::EventHelper
  helper Cms::ArchiveHelper

  def index
    y = params[:year]
    m = params[:month]

    if y.present? && m.present? && Date.valid_date?(y.to_i, m.to_i, 1)
      @year = y.to_i
      @month = m.to_i
      @day = Time.zone.today.day.to_i
    else
      @cur_path.sub(/\..+?$/, "").scan(/(\d{4})(\d{2})(\d{2})?$/).each do |y, m, d|
        d = 1 unless d
        if Date.valid_date?(y.to_i, m.to_i, d.to_i)
          @year = y.to_i
          @month = m.to_i
          @day = d.to_i
        end
      end

      if @year.blank? || @month.blank?
        @year  = Time.zone.today.year.to_i
        @month = Time.zone.today.month.to_i
        @day = Time.zone.today.day.to_i
      end
    end

    @current_month_date = Date.new(@year, @month, 1)
    @prev_month_date = @current_month_date.change(day: 1).advance(days: -1)
    @next_month_date = @current_month_date.advance(months: 1)
    @dates = []

    if @cur_part.parent.present?
      if @cur_part.parent.route == "cms/archive"
        @condition_hash = @cur_part.parent.try(:parent).try(:becomes_with_route).try(:condition_hash)
      else
        @condition_hash = @cur_part.parent.becomes_with_route.try(:condition_hash)
      end
    end
    start_date = @current_month_date.advance(days: -1 * @current_month_date.wday)
    close_date = start_date.advance(days: 7 * 6)

    (start_date...close_date).each do |d|
      @dates.push [ d, blog_update(d) ]
    end
  end

  private
    def blog_update(date)
      @condition_hash = {} unless @condition_hash
      Cms::Page.site(@cur_site).and_public(@cur_date).
        where(@condition_hash).
        where(:released.gt => date.beginning_of_day, :released.lt => date.end_of_day).exists?
    end
end
