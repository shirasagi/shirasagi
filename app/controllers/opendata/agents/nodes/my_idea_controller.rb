class Opendata::Agents::Nodes::MyIdeaController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::MypageFilter

  before_action :set_model
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

  protected
    def idea_node
      @idea_node ||= Opendata::Node::Idea.site(@cur_site).public.first
    end

    def set_model
      @model = Opendata::Idea
    end

    def set_item
      @item = @model.site(@cur_site).member(@cur_member).find params[:id]
      @item.attributes = fix_params
    end

    def fix_params
      { site_id: @cur_site.id, member_id: @cur_member.id, cur_node: idea_node }
    end

    def pre_params
      {}
    end

    def permit_fields
      @model.permitted_fields
    end

    def get_params
      params.require(:item).permit(permit_fields).merge(fix_params)
    end

  public
    def index
      @items = Opendata::Idea.site(@cur_site).member(@cur_member).
        order_by(updated: -1).
        page(params[:page]).
        per(20)

      render
    end

    def show
      render
    end

    def new
      @item = @model.new

      @item.dataset_ids = [params[:dataset]]
      @item.app_ids = [params[:app]]

      render
    end

    def create
      @item = @model.new get_params

      if @item.save
        redirect_to @cur_node.url, notice: t("views.notice.saved")
      else
        render action: :new
      end
    end

    def edit
      render
    end

    def update
      @item.attributes = get_params

      if @item.update
        redirect_to "#{@cur_node.url}#{@item.id}/", notice: t("views.notice.saved")
      else
        render action: :edit
      end
    end

    def delete
      render
    end

    def destroy
      if @item.destroy
        redirect_to @cur_node.url, notice: t("views.notice.deleted")
      else
        render action: :delete
      end
    end

end
