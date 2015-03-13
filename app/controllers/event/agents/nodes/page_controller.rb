class Event::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  include Event::EventHelper
  helper Event::EventHelper

  public
    def index
      @year  = Date.today.year.to_i
      @month = Date.today.month.to_i

      monthly
    end

    def monthly
      @year  = params[:year].to_i if @year.blank?
      @month = params[:month].to_i if @month.blank?

      if within_one_year?(Date.new(@year, @month, 1))
        index_monthly
      elsif within_one_year?(Date.new(@year, @month, 1).advance(months:  1, days: -1))
        index_monthly
      else
        raise "404"
      end
    end

    def daily
      @year  = params[:year].to_i
      @month = params[:month].to_i
      @day   = params[:day].to_i

      if within_one_year?(Date.new(@year, @month, @day))
        index_daily
      else
        raise "404"
      end
    end

  private
    def events(date)
      events = Cms::Page.site(@cur_site).public(@cur_date).
        where(@cur_node.condition_hash).
        where(:"event_dates".in => date).
        entries.
        sort_by{ |page| page.event_dates.size }
    end

    def index_monthly
      @events = {}
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
          @events[d] << [
            page,
            page.categories.in(id: @cur_node.st_categories.pluck(:id)).order_by(order: 1)
          ]
        end
      end

      render :monthly
    end

    def index_daily
      @date = Date.new(@year, @month, @day)
      @events = events([@date.mongoize]).map do |page|
        [
          page,
          page.categories.in(id: @cur_node.st_categories.pluck(:id)).order_by(order: 1)
        ]
      end

      render :daily
    end
end
