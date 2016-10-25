class Event::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  include Event::EventHelper
  helper Event::EventHelper

  def index
    @categories = []
    if @cur_node.parent
      @categories = Cms::Node.site(@cur_site).where({:id.in => @cur_node.parent.st_category_ids}).sort(filename: 1)
    end
    list_events
    @keyword = params[:search_keyword]
    @category_ids = params[:category_ids].present? ? params[:category_ids] : []
  end

  private
    def search_by_date(event_dates)
      search = {}
      search[:list_days] = {}
      search[:dates] = {}

      return search unless event_dates.present?

      list_days = {}
      days = []

      event_dates.split(/\r\n|\n/).each do |date|
        d = Date.parse(date)
        days << d
      end

      @start_date = days.first
      @close_date = days.last

      (@start_date...@close_date + 1.day).each do |d|
        list_days[d] = []
      end

      search[:list_days] = list_days
      search[:dates] = (@start_date...@close_date + 1.day).map { |m| m.mongoize }

      search
    end

    def list_events
      @events = {}
      search = {}

      search = search_by_date(params[:event_dates])
      event_list = Event::Page.search(
        keyword: params[:search_keyword],
        categories: params[:category_ids],
        dates: search[:dates]
      ).and_public.entries.sort_by{ |page| page.event_dates.size }

      event_list.each do |page|
        page.event_dates.split(/\r\n|\n/).each do |day|
          d = Date.parse(day)

          if search[:list_days].present?
            next unless search[:list_days][d]
          end

          @events[d] = [] if @events[d].blank?
          @events[d] << [
            page,
            page.categories.in(id: @cur_node.parent.st_category_ids).order_by(order: 1)
          ]
        end
      end

      @events = @events.sort_by { |key, value| key }
    end
end
