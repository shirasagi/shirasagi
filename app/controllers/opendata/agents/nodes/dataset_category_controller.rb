class Opendata::Agents::Nodes::DatasetCategoryController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper

  public
    def pages
      @item ||= Opendata::Node::Category.site(@cur_site).
        where(filename: /\/#{params[:name]}$/).first

      raise "404" unless @item

      Opendata::Dataset.site(@cur_site).where(category_ids: @item.id).public
    end

    def index
      @count = pages.size
      @search_url = search_datasets_path + "?s[category_id]=#{@item.id}"
      @rss_url = search_datasets_path + "index.rss?s[category_id]=#{@item.id}"

      controller.instance_variable_set :@cur_node, @item

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
        { name: "新着順", url: "#{@search_url}&sort=released", pages: @items, rss: "#{@rss_url}&sort=released" },
        { name: "人気順", url: "#{@search_url}&sort=popular", pages: @point_items, rss: "#{@rss_url}&sort=popular" },
        { name: "注目順", url: "#{@search_url}&sort=attention", pages: @download_items, rss: "#{@rss_url}&sort=attention" }
      ]

      cond = {
        route: Opendata::Dataset.new.route,
        site_id: @cur_site.id,
        category_ids: @item.id,
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
    end

    def nothing
      render nothing: true
    end
end
