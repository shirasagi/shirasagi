class Ads::AccessLogsController < ApplicationController
  include Cms::BaseFilter

  model Ads::AccessLog

  navi_view "ads/main/navi"
  menu_view "cms/crud/menu"

  before_action :set_year_month

  def index
    sy = Time.zone.today.year - 10
    ey = Time.zone.today.year
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

  def download
    @items = @model.site(@cur_site).where(node_id: @cur_node.id)

    if @month
      monthly_download
    elsif @year
      yearly_download
    else
      recent_download
    end
  end

  private
    def set_year_month
      if s = params[:s]
        @year  = s[:year].presence
        @month = s[:month].presence
      end
    end

    def recent_common
      @action = :recent
      @items = @items.order_by(date: -1, link_url: 1).
        page(params[:page]).per(50)
    end

    def recent
      recent_common
    end

    def recent_download
      recent_common

      csv = @items.to_csv
      send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "ads_access_logs_#{Time.zone.now.to_i}.csv"
    end

    def monthly_commont
      @action = :monthly
      sdate = Date.new @year.to_i, @month.to_i, 1
      edate = sdate + 1.month

      @max_cell = sdate.end_of_month.day
      @totals = {}

      @items = @items.where(date: { "$gte" => sdate, "$lt" => edate })

      @items.order_by(link_url: 1).each do |item|
        @totals[item.link_url] ||= {}
        @totals[item.link_url][item.date.day] = item.count
      end
    end

    def monthly
      monthly_commont
      render :total
    end

    def monthly_download
      monthly_commont
      send_total
    end

    def yearly_common
      @action = :yearly
      sdate = Date.new @year.to_i, 1, 1
      edate = sdate + 1.year

      @max_cell = 12
      @totals = {}

      @items = @items.where(date: { "$gte" => sdate, "$lt" => edate })

      pipes = []
      pipes << { "$match" => @items.selector }
      pipes << { "$group" => {
          _id: { link_url: "$link_url", month: { "$month" => "$date" } },
          count: { "$sum" => "$count" }
      } }
      pipes << { "$sort" => { "_id.link_url" => 1 } }

      @items.collection.aggregate(pipes).each do |data|
        url   = data["_id"]["link_url"]
        month = data["_id"]["month"]
        @totals[url] ||= {}
        @totals[url][month] = data["count"]
      end
    end

    def yearly
      yearly_common
      render :total
    end

    def yearly_download
      yearly_common
      send_total
    end

    def send_total(filename = "ads_access_logs_#{Time.zone.now.to_i}.csv")
      csv = CSV.generate do |data|
        header = []
        header << 'link_url'
        (1..@max_cell).each do |day|
          header << day
        end
        header << 'total'
        data << header

        @totals.each do |link_url, counts|
          total = 0
          row = []
          row << link_url
          (1..@max_cell).each do |day|
            count = counts[day].to_i
            total += count
            row << count
          end
          row << total
          data << row
        end
      end

      send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: filename
    end
end
