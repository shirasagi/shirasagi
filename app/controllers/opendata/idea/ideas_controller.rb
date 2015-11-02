class Opendata::Idea::IdeasController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Workflow::PageFilter
  helper Opendata::FormHelper

  model Opendata::Idea

  append_view_path "app/views/cms/pages"
  navi_view "opendata/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

  public
    def index
      @items = @model.site(@cur_site).node(@cur_node).allow(:read, @cur_user).
        search(params[:s]).
        order_by(updated: -1).
        page(params[:page]).per(50)
    end

    def show
      cond = { site_id: @cur_site.id, idea_id: params[:id] }
      @comments = Opendata::IdeaComment.where(cond).order_by(:created.asc)
    end

    def index_approve
      cond = {
        workflow_state: "request",
        workflow_approvers: {
          "$elemMatch" => { "user_id" => @cur_user._id, "state" => "request" }
        }
      }
      @ideas = Opendata::Idea.where(site_id: @cur_site.id).
        allow(:read, @cur_user).
        search(params[:s]).
        where(cond)

      @comments = Opendata::IdeaComment.where(site_id: @cur_site.id).
        allow(:read, @cur_user).
        search(params[:s]).
        where(cond)

      @items = Opendata::Idea.in(id: @ideas.map(&:id) + @comments.map(&:idea_id)).order_by(:created.desc)
      render file: :index
    end

    def index_request
      cond = { workflow_user_id: @cur_user._id }
      @ideas = Opendata::Idea.where(site_id: @cur_site.id).
        allow(:read, @cur_user).
        search(params[:s]).
        where(cond)

      @comments = Opendata::IdeaComment.where(site_id: @cur_site.id).
        allow(:read, @cur_user).
        search(params[:s]).
        where(cond)

      @items = Opendata::Idea.in(id: @ideas.map(&:id) + @comments.map(&:idea_id)).order_by(:created.desc)
      render file: :index
    end
end
