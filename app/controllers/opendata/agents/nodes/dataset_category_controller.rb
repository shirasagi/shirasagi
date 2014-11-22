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
      @count          = pages.size
      @search_url     = search_datasets_path + "?s[category_id]=#{@item.id}"
      @rss_url        = search_datasets_path + "index.rss?s[category_id]=#{@item.id}"
      @items          = pages.order_by(released: -1).limit(10)
      @point_items    = pages.order_by(point: -1).limit(10)
      @download_items = pages.order_by(downloaded: -1).limit(10)

      controller.instance_variable_set :@cur_node, @item

      @tabs = [
        { name: "新着順", url: "#{@search_url}&sort=released", pages: @items, rss: "#{@rss_url}&sort=released" },
        { name: "人気順", url: "#{@search_url}&sort=popular", pages: @point_items, rss: "#{@rss_url}&sort=popular" },
        { name: "注目順", url: "#{@search_url}&sort=attention", pages: @download_items, rss: "#{@rss_url}&sort=attention" }
      ]

      @areas = pages.aggregate_array(:area_ids).map do |data|
        rel = Opendata::Node::Area.site(@cur_site).public.where(id: data["id"]).first
        rel ? { "id" => rel.id, "name" => rel.name, "count" => data["count"] } : nil
      end.compact

      @tags     = pages.aggregate_array(:tags)

      @formats  = pages.aggregate_resources(:format)

      @licenses = pages.aggregate_resources(:license_id).map do |data|
        rel = Opendata::License.site(@cur_site).public.where(id: data["id"]).first
        rel ? { "id" => rel.id, "name" => rel.name, "count" => data["count"] } : nil
      end.compact
    end

    def nothing
      render nothing: true
    end
end
