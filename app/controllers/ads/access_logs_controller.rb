class Ads::AccessLogsController < ApplicationController
  include Cms::BaseFilter

  model Ads::AccessLog

  navi_view "ads/main/navi"

  public
    def index
      if s = params[:s]
        @year  = s[:year].presence
        @month = s[:month].presence
      end

      sy = Date.today.year - 10
      ey = Date.today.year
      @years = (sy..ey).to_a.reverse.map { |d| ["#{d}#{t('datetime.prompts.year')}", d] }
      @months = (1..12).to_a.map { |d| ["#{d}#{t('datetime.prompts.month')}", d] }

      @items = @model.site(@cur_site).where(node_id: @cur_node.id)

      if @month
        monthly
      elsif @year
        yearly
      else
        recent
      end
    end

  private
    def recent
      @items = @items.
        order_by(date: -1, link_url: 1).
        page(params[:page]).per(50)
    end

    def monthly
      sdate = Time.parse("#{@year}#{@month}01")
      edate = sdate.advance(months:  1)

      @max_cell = sdate.end_of_month.day
      @totals = {}

      @items = @items.where(date: { "$gte" => sdate, "$lt" => edate })

      @items.order_by(link_url: 1).each do |item|
        @totals[item.link_url] ||= {}
        @totals[item.link_url][item.date.day] = item.count
      end

      render :total
    end

    def yearly
      sdate = Time.parse("#{@year}0101")
      edate = sdate.advance(years:  1)

      @max_cell = 12
      @totals = {}

      @items = @items.where(date: { "$gte" => sdate, "$lt" => edate })

      pipes = []
      pipes << { "$match" => @items.selector }
      pipes << { "$group" => {
        _id: { link_url: "$link_url", month: { "$month" => "$date" } },
        count: { "$sum" =>  "$count" }
      } }
      pipes << { "$sort" => { "_id.link_url" => 1 } }

      @items.collection.aggregate(pipes).each do |data|
        url   = data["_id"]["link_url"]
        month = data["_id"]["month"]
        @totals[url] ||= {}
        @totals[url][month] = data["count"]
      end

      render :total
    end
end
