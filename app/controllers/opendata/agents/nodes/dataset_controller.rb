class Opendata::Agents::Nodes::DatasetController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::MypageFilter
  include Opendata::DatasetFilter

  before_action :set_dataset, only: [:show_point, :add_point, :point_members]
  skip_filter :logged_in?

  private
    def set_dataset
      @dataset_path = @cur_path.sub(/\/point\/.*/, ".html")

      @dataset = Opendata::Dataset.site(@cur_site).public.
        filename(@dataset_path).
        first

      raise "404" unless @dataset
    end

  public
    def pages
      Opendata::Dataset.site(@cur_site).public
    end

    def index
      @count          = pages.size
      @node_url       = "#{@cur_node.url}"
      @search_url     = search_datasets_path + "?"
      @rss_url        = search_datasets_path + "index.rss?"
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

      respond_to do |format|
        format.html { render }
        format.rss  { render_rss @cur_node, @items }
      end
    end

    def show_point
      @cur_node.layout = nil
      @mode = nil

      if logged_in?(redirect: false)
        @mode = :add

        cond = { site_id: @cur_site.id, member_id: @cur_member.id, dataset_id: @dataset.id }
        @mode = :cancel if point = Opendata::DatasetPoint.where(cond).first
      end
    end

    def add_point
      @cur_node.layout = nil
      raise "403" unless logged_in?(redirect: false)

      cond = { site_id: @cur_site.id, member_id: @cur_member.id, dataset_id: @dataset.id }

      if point = Opendata::DatasetPoint.where(cond).first
        point.destroy
        @dataset.inc point: -1
        @mode = :add
      else
        Opendata::DatasetPoint.new(cond).save
        @dataset.inc point: 1
        @mode = :cancel
      end

      render :show_point
    end

    def point_members
      @cur_node.layout = nil
      @items = Opendata::DatasetPoint.where(site_id: @cur_site.id, dataset_id: @dataset.id)
    end
end
