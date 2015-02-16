class Opendata::Agents::Nodes::IdeaController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::MypageFilter
  include Opendata::IdeaFilter

  before_action :set_idea, only: [:show_point, :add_point, :point_members]
  before_action :set_idea_comment, only: [:show_comment, :add_comment, :delete_comment]
  skip_filter :logged_in?

  private
    def set_idea
      @idea_path = @cur_path.sub(/\/point\/.*/, ".html")

      @idea = Opendata::Idea.site(@cur_site).public.
        filename(@idea_path).
        first

      raise "404" unless @idea
    end

    def set_idea_comment
      @idea_comment_path = @cur_path.sub(/\/comment\/.*/, ".html")

      @idea_comment = Opendata::Idea.site(@cur_site).public.
        filename(@idea_comment_path).
        first

      cond = { site_id: @cur_site.id, idea_id: @idea_comment.id }
      @comments = Opendata::IdeaComment.where(cond).order_by(:updated.asc)

      @manage_mode = true if logged_in?(redirect: false) && @cur_member.id == @idea_comment.member_id
      @comment_mode = logged_in?(redirect: false)

      raise "404" unless @idea_comment
    end

    def update_commented_count(member_ids, count)
      member_ids.each do |member_id|
        notice = Opendata::MemberNotice.where({member_id: member_id}).first
        if notice
          commented_count = notice.commented_count || 0
          notice.commented_count = notice.commented_count + count
          notice.save
        else
          notice_new = { site_id: @cur_site.id, member_id: member_id, commented_count: 1 }
          Opendata::MemberNotice.new(notice_new).save
        end
      end
    end

  public
    def pages
      Opendata::Idea.site(@cur_site).public
    end

    def index
      @count          = pages.size
      @node_url       = "#{@cur_node.url}"
      @search_url     = search_ideas_path + "?"
      @rss_url        = search_ideas_path + "rss.xml?"
      @items          = pages.order_by(released: -1).limit(10)
      @point_items    = pages.order_by(point: -1).limit(10)
      @comment_items = pages.excludes(commented: nil).order_by(commented: -1).limit(10)

      @tabs = [
        { name: "新着順", url: "#{@search_url}&sort=released", pages: @items, rss: "#{@rss_url}&sort=released" },
        { name: "人気順", url: "#{@search_url}&sort=popular", pages: @point_items, rss: "#{@rss_url}&sort=popular" },
        { name: "注目順", url: "#{@search_url}&sort=attention", pages: @comment_items, rss: "#{@rss_url}&sort=attention" }
      ]

      max = 50
      @areas    = aggregate_areas
      @tags     = aggregate_tags(max)

      respond_to do |format|
        format.html { render }
        format.rss  { render_rss @cur_node, @items }
        end
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

    def show_comment
      @cur_node.layout = nil
    end

    def add_comment
      @cur_node.layout = nil
      raise "403" unless logged_in?(redirect: false)

      idea_id = @idea_comment.id
      idea = Opendata::Idea.site(@cur_site).find(idea_id)

      new_comment = { site_id: @cur_site.id, member_id: @cur_member.id, idea_id: idea_id, text: params[:comment_body]}
      Opendata::IdeaComment.new(new_comment).save

      idea.commented = Time.now
      idea.save

      member_ids = []
      other_comments = Opendata::IdeaComment.where({idea_id: @idea_comment.id})
      other_comments = other_comments.not_in({member_id: [@cur_member.id, @idea_comment.member.id]})
      other_comments.each do |other_comment|
        member_ids << other_comment.member_id
      end

      member_ids << @idea_comment.member_id if @idea_comment.member_id != @cur_member.id

      update_commented_count(member_ids.uniq, 1)

      render :show_comment
    end

    def delete_comment
      @cur_node.layout = nil

      comment = Opendata::IdeaComment.find params[:comment]
      if comment
        comment.deleted = Time.now
        comment.save
      end

      render :show_comment
    end

    def show_dataset
      @cur_node.layout = nil

      idea_path = @cur_path.sub(/\/dataset\/.*/, ".html")

      idea = Opendata::Idea.site(@cur_site).public.
        filename(idea_path).
        first
      raise "404" unless idea

      @dataset = Opendata::Dataset.site(@cur_site).find(idea.dataset_id) if idea.dataset_id
    end

    def show_app
      @cur_node.layout = nil

      idea_path = @cur_path.sub(/\/app\/.*/, ".html")

      idea = Opendata::Idea.site(@cur_site).public.
      filename(idea_path).
      first
      raise "404" unless idea

      @app = Opendata::App.site(@cur_site).find(idea.app_id) if idea.app_id
    end

end
