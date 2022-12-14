class Opendata::Idea::CommentsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Opendata::Idea::CommentFilter

  model Opendata::IdeaComment

  navi_view "opendata/main/navi"

  before_action :set_idea

  private

  def set_idea
    cond = { site_id: @cur_site.id, idea_id: params[:idea_id] }
    @comments ||= Opendata::IdeaComment.where(cond)

    idea = Opendata::Idea.site(@cur_site).node(@cur_node).find params[:idea_id]
    @crumbs << [idea.name, opendata_idea_path(id: idea.id)]

  end

  def set_item
    @item = Opendata::IdeaComment.where(site_id: @cur_site.id).find params[:id]
  end

  public

  def index
    @items = @comments.search(params[:s]).order_by(:created.desc)
    @items = @items.page(params[:page]).per(50)
  end

  def show
  end

  def create
    idea = Opendata::Idea.site(@cur_site).find(params[:idea_id].to_s)

    @item = Opendata::IdeaComment.new(site_id: @cur_site.id, idea_id: idea.id, user_id: @cur_user.id)
    @item.attributes = params.require(:item).permit(*@model.permit_params)
    @item.save

    idea.commented = Time.zone.now
    idea.total_comment += 1
    idea.cur_site = idea.site
    idea.save

    update_member_notices(idea)

    render_create @item.valid?
  end

  def soft_delete
    if request.get? || request.head?
      set_item
      render
      return
    end

    comment = Opendata::IdeaComment.where(site_id: @cur_site.id, id: params[:id]).first
    comment.comment_deleted = Time.zone.now
    comment.apply_status("closed", workflow_reset: true)
    comment.save
    render_destroy comment
  end

  def undo_delete
    if request.get? || request.head?
      set_item
      render
      return
    end

    comment = Opendata::IdeaComment.where(site_id: @cur_site.id, id: params[:id]).first
    comment.comment_deleted = nil
    comment.apply_status("public", workflow_reset: true)
    comment.save
    render_update comment
  end
end
