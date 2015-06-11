class Opendata::Agents::Nodes::Idea::IdeaController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Opendata::MemberFilter
  include Opendata::Idea::IdeaFilter
  helper Opendata::UrlHelper

  before_action :set_idea, only: [:show_point, :add_point, :point_members]
  skip_filter :logged_in?

  private
    def set_idea
      @idea_path = Opendata::Idea.to_idea_path(@cur_path)
      @idea = Opendata::Idea.site(@cur_site).public.
        filename(@idea_path).
        first

      raise "404" unless @idea
    end

  public
    def pages
      Opendata::Idea.site(@cur_site).public
    end

    def index
      @count          = pages.size
      @node_url       = "#{@cur_node.url}"
      @search_path    = view_context.method(:search_ideas_path)
      @rss_path       = ->(options = {}) { view_context.build_path("#{view_context.search_ideas_path}rss.xml", options) }
      @tabs = []
      Opendata::Idea.sort_options.each do |options|
        @tabs << { name: options[0],
                   url: "#{@search_path.call("sort" => "#{options[1]}")}",
                   pages: pages.sort_criteria(options[1]).limit(10),
                   rss: "#{@rss_path.call("sort" => "#{options[1]}")}" }
      end

      max = 50
      @areas    = aggregate_areas(max)
      @tags     = aggregate_tags(max)

      respond_to do |format|
        format.html { render }
        format.rss  { render_rss @cur_node, @items }
        end
    end

    def rss
      @items = pages.order_by(released: -1).limit(100)
      render_rss @cur_node, @items
    end

    def show_point
      @cur_node.layout = nil
      @mode = nil

      if logged_in?(redirect: false)
        @mode = :add

        cond = { site_id: @cur_site.id, member_id: @cur_member.id, idea_id: @idea.id }
        @mode = :cancel if point = Opendata::IdeaPoint.where(cond).first
      end
    end

    def add_point
      @cur_node.layout = nil
      raise "403" unless logged_in?(redirect: false)

      cond = { site_id: @cur_site.id, member_id: @cur_member.id, idea_id: @idea.id }

      if point = Opendata::IdeaPoint.where(cond).first
        point.destroy
        @idea.inc point: -1
        @mode = :add
      else
        Opendata::IdeaPoint.new(cond).save
        @idea.inc point: 1
        @mode = :cancel
      end

      render :show_point
    end

    def point_members
      @cur_node.layout = nil
      @items = Opendata::IdeaPoint.where(site_id: @cur_site.id, idea_id: @idea.id)
    end

    def show_dataset
      @cur_node.layout = nil

      idea_path = @cur_path.sub(/\/dataset\/.*/, ".html")

      @idea_ds = Opendata::Idea.site(@cur_site).public.
        filename(idea_path).
        first
      raise "404" unless @idea_ds

    end

    def show_app
      @cur_node.layout = nil

      idea_path = @cur_path.sub(/\/app\/.*/, ".html")

      @idea_ap = Opendata::Idea.site(@cur_site).public.
      filename(idea_path).
      first
      raise "404" unless @idea_ap

    end

end
