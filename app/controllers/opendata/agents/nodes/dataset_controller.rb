class Opendata::Agents::Nodes::DatasetController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::MypageFilter

  before_action :set_dataset, only: [:show_point, :add_point]
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
      Opendata::Dataset.site(@cur_site).node(@cur_node).public
    end

    def index
      @count = pages.size
      @search_url = search_datasets_path + "?"

      @items = pages.
        order_by(released: -1).
        limit(10)

      @point_items = pages.
        order_by(point: -1).
        limit(10)

      @download_items = pages.
        order_by(downloaded: -1).
        limit(10)

      @tabs = [
        { name: "新着順", url: "#{@search_url}&sort=released", pages: @items },
        { name: "人気順", url: "#{@search_url}&sort=popular", pages: @point_items },
        { name: "注目順", url: "#{@search_url}&sort=attention", pages: @download_items }
      ]

      cond = {
        route: Opendata::Dataset.new.route,
        site_id: @cur_site.id,
        filename: /^#{@cur_node.filename}\//,
        depth: @cur_node.depth + 1,
        state: "public"
      }

      @areas = []
      Opendata::Dataset.total_field(:area_ids, cond).each do |m|
        if item = Opendata::Node::Area.site(@cur_site).public.where(id: m["id"]).first
          item[:count] = m["count"]
          @areas << item
        end
      end

      @tags = Opendata::Dataset.total_field(:tags, cond)
      @formats = Opendata::Dataset.total_field("resources.format", cond)
      @licenses = Opendata::Dataset.total_field(:license, cond)

      render
    end

    def show_point
      if logged_in?(redirect: false)
        mode = :entry
        cond = { site_id: @cur_site.id, member_id: @cur_member.id, dataset_id: @dataset.id }
        mode = :cancel if point = Opendata::DatasetPoint.where(cond).first
      else
        mode = :login
      end

      render json: { point: @dataset.point, mode: mode }.to_json
    end

    def add_point
      raise "403" unless logged_in?(redirect: false)

      cond = { site_id: @cur_site.id, member_id: @cur_member.id, dataset_id: @dataset.id }

      if point = Opendata::DatasetPoint.where(cond).first
        point.destroy
        @dataset.inc point: -1
        mode = :entry
      else
        Opendata::DatasetPoint.new(cond).save
        @dataset.inc point: 1
        mode = :cancel
      end

      render json: { point: @dataset.point, mode: mode }.to_json
    end
end
