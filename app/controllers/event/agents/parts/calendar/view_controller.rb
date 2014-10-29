module Event::Agents::Parts::Calendar
  class ViewController < ApplicationController
    include Cms::PartFilter::View
    helper Event::EventHelper

    public
      def index
        y = params[:year]
        m = params[:month]

        if y.present? && m.present? && Date.valid_date?(y.to_i, m.to_i, 1)
          @year = y.to_i
          @month = m.to_i
          @day = Date.today.day.to_i
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
            @year  = Date.today.year.to_i
            @month = Date.today.month.to_i
            @day = Date.today.day.to_i
          end
        end

        @current_month_date = Date.new(@year, @month, 1)
        @prev_month_date = @current_month_date.change(day: 1).advance(days: -1)
        @next_month_date = @current_month_date.advance(months:  1)
        @dates = []

        if @cur_part.parent.present?
          @condition_hash = @cur_part.parent.becomes_with_route.try(:condition_hash)
        end

        start_date = @current_month_date.advance(days: -1 * @current_month_date.wday)
        close_date = start_date.advance(days: 7 * 6)

        (start_date...close_date).each do |d|
          @dates.push [ d, events(d) ]
        end
      end

    private
      def events(date)
        @condition_hash = {} unless @condition_hash
        events = Cms::Page.site(@cur_site).public(@cur_date).
          where(@condition_hash).
          where(:"event_dates".in => [date.mongoize]).
          entries.
          sort_by{ |page| page.event_dates.size }
      end
  end
end
