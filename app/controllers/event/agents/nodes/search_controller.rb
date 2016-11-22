class Event::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  include Event::EventHelper
  helper Event::EventHelper
  helper Cms::ListHelper

  def index
    @categories = []
    @items = []
    if @cur_node.parent
      @categories = Cms::Node.site(@cur_site).where({:id.in => @cur_node.parent.st_category_ids}).sort(filename: 1)
    end
    if params[:search_keyword].present? ||
        params[:event_dates].present? ||
        params[:category_ids].present?
      list_events
    end
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

    def lte_close_date?
      params[:event][0][:start_date].blank? && params[:event][0][:close_date].present?
    end

    def gte_start_date?
      params[:event][0][:close_date].blank? && params[:event][0][:start_date].present?
    end

    def list_events
      @items = {}
      search = {}
      if lte_close_date?
        key_date = "close_date"
        search[:dates] = Date.parse(params[:event][0][:close_date])
        @close_date = search[:dates]
      elsif gte_start_date?
        key_date = "start_date"
        search[:dates] = Date.parse(params[:event][0][:start_date])
        @start_date = search[:dates]
      else
        search = search_by_date(params[:event_dates])
        key_date = "dates"
      end

      @items = Event::Page.site(@cur_site).search(
        keyword: params[:search_keyword],
        categories: params[:category_ids],
        :"#{key_date}" => search[:dates]
      ).and_public.page(params[:page]).
      per(@cur_node.limit).entries.
      sort_by{ |page| page.event_dates.size }

      @items = @items.sort_by { |key, value| key }
    end
end
