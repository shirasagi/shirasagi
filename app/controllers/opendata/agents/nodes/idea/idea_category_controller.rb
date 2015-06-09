class Opendata::Agents::Nodes::Idea::IdeaCategoryController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::Idea::IdeaFilter

  public
    def pages
      @item ||= Opendata::Node::Category.site(@cur_site).
        where(filename: /\/#{params[:name]}$/).first
      raise "404" unless @item

      @cur_node.name = @item.name

      Opendata::Idea.site(@cur_site).where(category_ids: @item.id).public
    end

    def index
      @count          = pages.size
      @node_url       = "#{@cur_node.url}#{params[:name]}/"
      default_options = { "s[category_id]" => "#{@item.id}" }
      @search_path    = ->(options = {}) { search_ideas_path(default_options.merge(options)) }
      @rss_path       = ->(options = {}) { build_path("#{search_ideas_path}rss.xml", default_options.merge(options)) }
      @items          = pages.order_by(updated: -1).limit(10)
      @point_items    = pages.order_by(point: -1).limit(10)
      @comment_items = pages.excludes(commented: nil).order_by(commented: -1).limit(10)

      controller.instance_variable_set :@cur_node, @item

      @tabs = [
        { name: "新着順",
          url: "#{@search_path.call("sort" => "updated")}",
          pages: @items,
          rss: "#{@rss_path.call("sort" => "updated")}" },
        { name: "人気順",
          url: "#{@search_path.call("sort" => "popular")}",
          pages: @point_items,
          rss: "#{@rss_path.call("sort" => "popular")}" },
        { name: "注目順",
          url: "#{@search_path.call("sort" => "attention")}",
          pages: @comment_items,
          rss: "#{@rss_path.call("sort" => "attention")}" }
      ]

      max = 50
      @areas    = aggregate_areas(max)
      @tags     = aggregate_tags(max)
    end

    def rss
      @items = pages.order_by(updated: -1).limit(100)
      render_rss @cur_node, @items
    end

    def nothing
      render nothing: true
    end
end
