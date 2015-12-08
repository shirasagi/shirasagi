class Opendata::Agents::Nodes::Idea::CommentController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Opendata::MemberFilter
  include Opendata::Idea::CommentFilter
  helper Opendata::UrlHelper

  before_action :accept_cors_request
  before_action :set_comments, only: [:index, :add, :delete]
  before_action :set_workflow

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

      def set_workflow
        @cur_site = Cms::Site.find(@cur_site.id)
        @route = @cur_site.idea_workflow_route
      end
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

      comment = Opendata::IdeaComment.new(new_comment)
      comment.apply_status("request", member: @cur_member, route: @route) if @route
      comment.save

      if @route
        args = {
          m_id: @cur_member.id,
          t_uid: comment.workflow_approvers.first[:user_id],
          site: @cur_site,
          idea: @idea,
          comment: comment,
          url: ::File.join(
            @cur_site.full_url,
            opendata_idea_comment_path(cid: @cur_node.id, site: @cur_site.host, idea_id: @idea.id, id: comment.id))
        }
        Opendata::Mailer.request_idea_comment_mail(args).deliver_now rescue nil
      end

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
        comment.apply_status("closed", workflow_reset: true)
        comment.comment_deleted = Time.zone.now
        comment.save
      end

      render :index
    end

end
