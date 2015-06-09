class Opendata::Agents::Nodes::Idea::CommentController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::MypageFilter
  include Opendata::Idea::CommentFilter

  before_action :accept_cors_request
  before_action :set_comments, only: [:index, :add, :delete]

  skip_filter :logged_in?

  private
    def set_comments
      @idea_path = Opendata::Idea.to_idea_path(@cur_path)

      @idea = Opendata::Idea.site(@cur_site).public.
        filename(@idea_path).
        first

      cond = { site_id: @cur_site.id, idea_id: @idea.id }
      @comments = Opendata::IdeaComment.where(cond).order_by(:created.asc)

      @comment_mode = logged_in?(redirect: false)

      raise "404" unless @idea
    end

  public
    def index
      @cur_node.layout = nil
    end

    def add
      @cur_node.layout = nil
      raise "403" unless logged_in?(redirect: false)

      idea_id = @idea.id
      idea = Opendata::Idea.site(@cur_site).find(idea_id)

      new_comment = { site_id: @cur_site.id, member_id: @cur_member.id, idea_id: idea_id, text: params[:comment_body]}
      Opendata::IdeaComment.new(new_comment).save

      idea.commented = Time.zone.now
      idea.total_comment = @comments.count
      idea.save

      update_member_notices(idea)

      render :index
    end

    def delete
      @cur_node.layout = nil

      comment = Opendata::IdeaComment.find params[:comment]
      if comment
        comment.comment_deleted = Time.zone.now
        comment.save
      end

      render :index
    end

end
