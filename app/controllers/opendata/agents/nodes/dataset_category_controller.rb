class Opendata::Agents::Nodes::DatasetCategoryController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::DatasetFilter

  public
    def pages
      @item ||= Opendata::Node::Category.site(@cur_site).
        where(filename: /\/#{params[:name]}$/).first
      raise "404" unless @item

      @cur_node.name = @item.name

      Opendata::Dataset.site(@cur_site).where(category_ids: @item.id).public
    end

    def index
      @count          = pages.size
      @node_url       = "#{@cur_node.url}#{params[:name]}/"
      @search_path    = ->(options = {}) { search_datasets_path({ "s[category_id]" => "#{@item.id}" }.merge(options)) }
      @rss_path       = ->(options = {}) { build_path("#{search_datasets_path}rss.xml", { "s[category_id]" => "#{@item.id}" }.merge(options)) }
      @items          = pages.order_by(released: -1).limit(10)
      @point_items    = pages.order_by(point: -1).limit(10)
      @download_items = pages.order_by(downloaded: -1).limit(10)

      controller.instance_variable_set :@cur_node, @item

      @tabs = [
        { name: "新着順", url: "#{@search_path.call("sort" => "released")}", pages: @items, rss: "#{@rss_path.call("sort" => "released")}" },
        { name: "人気順", url: "#{@search_path.call("sort" => "popular")}", pages: @point_items, rss: "#{@rss_path.call("sort" => "popular")}" },
        { name: "注目順", url: "#{@search_path.call("sort" => "attention")}", pages: @download_items, rss: "#{@rss_path.call("sort" => "attention")}" }
      ]

      max = 50
      @areas    = aggregate_areas
      @tags     = aggregate_tags(max)
      @formats  = aggregate_formats(max)
      @licenses = aggregate_licenses(max)
    end

    def rss
      @items = pages.order_by(released: -1).limit(100)
      render_rss @cur_node, @items
    end

    def nothing
      render nothing: true
    end
end
