class Opendata::Agents::Nodes::CommentController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::MypageFilter

  before_action :accept_cors_request
  #before_action :set_idea
  before_action :set_idea_comment, only: [:show_comment, :add_comment, :delete_comment]

  skip_filter :logged_in?

  private
#    def set_idea
#      @idea_path = @cur_path.sub(/\/comment\/.*/, ".html")
#
#      @idea = Opendata::Idea.site(@cur_site).public.
#        filename(@idea_path).
#        first
#
#      raise "404" unless @idea
#    end

    def set_idea_comment
      @idea_comment_path = Opendata::Idea.to_idea_path(@cur_path)

      @idea_comment = Opendata::Idea.site(@cur_site).public.
        filename(@idea_comment_path).
        first

      cond = { site_id: @cur_site.id, idea_id: @idea_comment.id }
      @comments = Opendata::IdeaComment.where(cond).order_by(:created.asc)

      @comment_mode = logged_in?(redirect: false)

      raise "404" unless @idea_comment
    end

    def update_commented_count(member_ids, count)
      member_ids.each do |member_id|
        notice = Opendata::MemberNotice.where({site_id: @cur_site.id, member_id: member_id}).first
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
#    def index
#      redirect_to @idea_path
#    end

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

      idea.commented = Time.zone.now
      idea.total_comment += 1
      idea.save

      member_ids = []
      other_comments = Opendata::IdeaComment.where({idea_id: @idea_comment.id})
      other_comments = other_comments.not_in({member_id: [@cur_member.id]})
      other_comments = other_comments.not_in({member_id: [@idea_comment.member_id]}) if @idea_comment.member_id.present?
      other_comments.each do |other_comment|
        member_ids << other_comment.member_id
      end

      if @idea_comment.member_id.present? && @idea_comment.member_id != @cur_member.id
        member_ids << @idea_comment.member_id
      end

      update_commented_count(member_ids.uniq, 1)

      render :show_comment
    end

    def delete_comment
      @cur_node.layout = nil

      comment = Opendata::IdeaComment.find params[:comment]
      if comment
        comment.comment_deleted = Time.zone.now
        comment.save
      end

      render :show_comment
    end

end
