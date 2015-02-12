class Opendata::Agents::Nodes::AppController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::MypageFilter
  include Opendata::AppFilter

  before_action :set_app, only: [:show_point, :add_point, :point_members]
  skip_filter :logged_in?

  private
    def set_app
      @app_path = @cur_path.sub(/\/point\/.*/, ".html")

      @app = Opendata::App.site(@cur_site).public.
        filename(@app_path).
        first

      raise "404" unless @app
    end

  public
    def pages
      Opendata::App.site(@cur_site).public
    end

    def index
      @count          = pages.size
      @node_url       = "#{@cur_node.url}"
      @search_url     = search_apps_path + "?"
      @rss_url        = search_apps_path + "rss.xml?"
      @items          = pages.order_by(released: -1).limit(10)
      @point_items    = pages.order_by(point: -1).limit(10)
      @download_items = pages.order_by(downloaded: -1).limit(10)

      @tabs = [
        { name: "新着順", url: "#{@search_url}&sort=released", pages: @items, rss: "#{@rss_url}&sort=released" },
        { name: "人気順", url: "#{@search_url}&sort=popular", pages: @point_items, rss: "#{@rss_url}&sort=popular" },
        { name: "注目順", url: "#{@search_url}&sort=attention", pages: @download_items, rss: "#{@rss_url}&sort=attention" }
      ]

      max = 50
      @areas    = aggregate_areas
      @tags     = aggregate_tags(max)
      @formats  = aggregate_formats(max)
      @licenses = aggregate_licenses(max)
    end

    def download
      @model = Opendata::App
      @item = @model.site(@cur_site).find_by(id: params[:app], appfilename: params[:appfilename].force_encoding("utf-8"))
      @item.inc downloaded: 1

      send_file @item.file.path, type: @item.content_type, filename: @item.appfilename,
        disposition: :attachment, x_sendfile: true
    end

    def rss
      @items = pages.order_by(released: -1).limit(100)
      render_rss @cur_node, @items
    end

    def show_point
      @cur_node.layout = nil
      @mode = nil

      if logged_in?(redirect: false)
        @mode = :add

        cond = { site_id: @cur_site.id, member_id: @cur_member.id, app_id: @app.id }
        @mode = :cancel if point = Opendata::AppPoint.where(cond).first
      end
    end

    def add_point
      @cur_node.layout = nil
      raise "403" unless logged_in?(redirect: false)

      cond = { site_id: @cur_site.id, member_id: @cur_member.id, app_id: @app.id }

      if point = Opendata::AppPoint.where(cond).first
        point.destroy
        @app.inc point: -1
        @mode = :add
      else
        Opendata::AppPoint.new(cond).save
        @app.inc point: 1
        @mode = :cancel
      end

      render :show_point
    end

    def point_members
      @cur_node.layout = nil
      @items = Opendata::AppPoint.where(site_id: @cur_site.id, app_id: @app.id)
    end

    def show
      @model = Opendata::App
      @item = @model.site(@cur_site).find(params[:id])

      render
    end
end
