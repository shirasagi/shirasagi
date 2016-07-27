class Opendata::Agents::Nodes::AppCategoryController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::AppFilter

  public
    def pages
      @item ||= Opendata::Node::Category.site(@cur_site).
        where(filename: /\/#{params[:name]}$/).first
      raise "404" unless @item

      @cur_node.name = @item.name

      Opendata::App::App.site(@cur_site).where(category_ids: @item.id).public
    end

    def index
      @count          = pages.size
      @node_url       = "#{@cur_node.url}#{params[:name]}/"
      default_options = { "s[category_id]" => "#{@item.id}" }
      @search_path    = ->(options = {}) { search_apps_path(default_options.merge(options)) }
      @rss_path       = ->(options = {}) { build_path("#{search_apps_path}rss.xml", default_options.merge(options)) }
      @items          = pages.order_by(released: -1).limit(10)
      @point_items    = pages.order_by(point: -1).limit(10)
      @execute_items   = pages.order_by(executed: -1).limit(10)

      controller.instance_variable_set :@cur_node, @item

      @tabs = [
        { name: "新着順",
          url: "#{@search_path.call("sort" => "released")}",
          pages: @items,
          rss: "#{@rss_path.call("sort" => "released")}" },
        { name: "人気順",
          url: "#{@search_path.call("sort" => "popular")}",
          pages: @point_items,
          rss: "#{@rss_path.call("sort" => "popular")}" },
        { name: "注目順",
          url: "#{@search_path.call("sort" => "attention")}",
          pages: @execute_items,
          rss: "#{@rss_path.call("sort" => "attention")}" }
      ]

      max = 50
      @areas    = aggregate_areas(max)
      @tags     = aggregate_tags(max)
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
