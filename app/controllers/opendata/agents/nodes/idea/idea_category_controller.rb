class Opendata::Agents::Nodes::Idea::IdeaCategoryController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::Idea::IdeaFilter

  private
    def pages
      @cur_node.cur_subcategory = params[:name]
      @item = @cur_node.related_category
      raise "404" unless @item

      @cur_node.name = @item.name

      Opendata::Idea.site(@cur_site).search(site: @cur_site, category_id: @item.id).public
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
      @search_path    = ->(options = {}) { search_ideas_path(default_options.merge(options)) }
      @rss_path       = ->(options = {}) { build_path("#{search_ideas_path}rss.xml", default_options.merge(options)) }
      @items          = pages.order_by(updated: -1).limit(10)
      @point_items    = pages.order_by(point: -1).limit(10)
      @comment_items  = pages.excludes(commented: nil).order_by(commented: -1).limit(10)
      @idea_node      = @cur_node.parent_idea_node

      controller.instance_variable_set :@cur_node, @item

      @tabs = []
      if @idea_node.show_tab?("released")
        @tabs << { name: @idea_node.tab_title("released").presence || I18n.t("opendata.sort_options.released"),
          id: "released",
          url: "#{@search_path.call("sort" => "updated")}",
          pages: @items,
          rss: "#{@rss_path.call("sort" => "updated")}" }
      end
      if @idea_node.show_tab?("popular")
        @tabs << { name: @idea_node.tab_title("popular").presence || I18n.t("opendata.sort_options.popular"),
          id: "popular",
          url: "#{@search_path.call("sort" => "popular")}",
          pages: @point_items,
          rss: "#{@rss_path.call("sort" => "popular")}" }
      end
      if @idea_node.show_tab?("attention")
        @tabs << { name: @idea_node.tab_title("attention").presence || I18n.t("opendata.sort_options.attention"),
          id: "attention",
          url: "#{@search_path.call("sort" => "attention")}",
          pages: @comment_items,
          rss: "#{@rss_path.call("sort" => "attention")}" }
      end

      max = 50
      @areas    = aggregate_areas(max)
      @tags     = aggregate_tags(max)
    end

    def rss
      @items = pages.order_by(updated: -1).limit(100)
      render_rss @cur_node, @items
    end
end
