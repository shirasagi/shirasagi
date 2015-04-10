class Opendata::Agents::Nodes::IdeaCategoryController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::IdeaFilter

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
      @search_url     = search_ideas_path + "?s[category_id]=#{@item.id}"
      @rss_url        = search_ideas_path + "rss.xml?s[category_id]=#{@item.id}"
      @items          = pages.order_by(updated: -1).limit(10)
      @point_items    = pages.order_by(point: -1).limit(10)
      @comment_items = pages.excludes(commented: nil).order_by(commented: -1).limit(10)

      controller.instance_variable_set :@cur_node, @item

      @tabs = [
        { name: "新着順", url: "#{@search_url}&sort=updated", pages: @items, rss: "#{@rss_url}&sort=updated" },
        { name: "人気順", url: "#{@search_url}&sort=popular", pages: @point_items, rss: "#{@rss_url}&sort=popular" },
        { name: "注目順", url: "#{@search_url}&sort=attention", pages: @comment_items, rss: "#{@rss_url}&sort=attention" }
      ]

      max = 50
      @areas    = aggregate_areas
      @tags     = aggregate_tags(max)
    end

    def nothing
      render nothing: true
    end
end
