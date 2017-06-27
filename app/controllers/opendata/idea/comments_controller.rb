class Opendata::Idea::CommentsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Opendata::Idea::CommentFilter
  helper Opendata::FormHelper

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
    idea_id = params[:idea_id]
    cond = { site_id: @cur_site.id, idea_id: idea_id, user_id: @cur_user.id,
             text: params[:item][:text],
             contact_state: params[:item][:contact_state],
             contact_charge: params[:item][:contact_charge],
             contact_tel: params[:item][:contact_tel],
             contact_fax: params[:item][:contact_fax],
             contact_email: params[:item][:contact_email],
             contact_link_url: params[:item][:contact_link_url],
             contact_link_name: params[:item][:contact_link_name],
             state: params[:item][:state]
           }
    contact_group_id = params[:item][:contact_group_id]
    cond[:contact_group_id] = contact_group_id if contact_group_id.present?

    @item = Opendata::IdeaComment.new(cond)
    @item.save

    idea = Opendata::Idea.site(@cur_site).find(idea_id)
    idea.commented = Time.zone.now
    idea.total_comment += 1
    idea.cur_site = idea.site
    idea.save

    update_member_notices(idea)

    render_create @item.valid?
  end

  def destroy
    comment = Opendata::IdeaComment.where(site_id: @cur_site.id, id: params[:id]).first
    comment.comment_deleted = Time.zone.now
    comment.apply_status("closed", workflow_reset: true)
    comment.save
    render_destroy comment
  end

end
