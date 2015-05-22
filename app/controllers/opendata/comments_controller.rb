class Opendata::CommentsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
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
      @items = @comments.search(params[:s]).order_by(:created.asc)
      @items = @items.page(params[:page]).per(50)
    end

    def show
    end

    def create
      cond = { site_id: @cur_site.id, idea_id: params[:idea_id], user_id: @cur_user.id, text: params[:item][:text] }
      @item = Opendata::IdeaComment.new(cond)
      @item.save
      render_create @item.valid?
    end

    def destroy
      comment = Opendata::IdeaComment.where(site_id: @cur_site.id, id: params[:id]).first
      comment.comment_deleted = Time.zone.now
      comment.save
      render_destroy comment
    end

end
