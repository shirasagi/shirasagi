class Opendata::Agents::Nodes::App::AppCategoryController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::App::AppFilter

  private
    def pages
      @cur_node.cur_subcategory = params[:name]
      @item = @cur_node.related_category
      raise "404" unless @item

      @cur_node.name = @item.name

      Opendata::App.site(@cur_site).search(site: @cur_site, category_id: @item.id).and_public
    end

    def node_url
      if name = params[:name]
        "#{@cur_node.url}#{name}/"
      else
        "#{@cur_node.url}"
      end
    end

  public
    def index
      @count          = pages.size
      @node_url       = node_url
      default_options = { "s[category_id]" => "#{@item.id}" }
      @search_path    = ->(options = {}) { search_apps_path(default_options.merge(options)) }
      @rss_path       = ->(options = {}) { build_path("#{search_apps_path}rss.xml", default_options.merge(options)) }
      @items          = pages.order_by(released: -1).limit(10)
      @point_items    = pages.order_by(point: -1).limit(10)
      @execute_items  = pages.order_by(executed: -1).limit(10)
      @app_node       = @cur_node.parent_app_node

      controller.instance_variable_set :@cur_node, @item

      @tabs = []
      if @app_node.show_tab?("released")
        @tabs << { name: @app_node.tab_title("released").presence || I18n.t("opendata.sort_options.released"),
            id: "released",
            url: "#{@search_path.call("sort" => "released")}",
            pages: @items,
            rss: "#{@rss_path.call("sort" => "released")}" }
      end
      if @app_node.show_tab?("popular")
        @tabs << { name: @app_node.tab_title("popular").presence || I18n.t("opendata.sort_options.popular"),
            id: "popular",
            url: "#{@search_path.call("sort" => "popular")}",
            pages: @point_items,
            rss: "#{@rss_path.call("sort" => "popular")}" }
      end
      if @app_node.show_tab?("attention")
        @tabs << { name: @app_node.tab_title("attention").presence || I18n.t("opendata.sort_options.attention"),
            id: "attention",
            url: "#{@search_path.call("sort" => "attention")}",
            pages: @execute_items,
            rss: "#{@rss_path.call("sort" => "attention")}" }
      end

      max = 50
      @areas    = aggregate_areas(max)
      @tags     = aggregate_tags(max)
      @licenses = aggregate_licenses(max)
    end

    def rss
      @items = pages.order_by(released: -1).limit(100)
      render_rss @cur_node, @items
    end
end
