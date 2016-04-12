class Gws::Board::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Board::Post

  before_action :set_category
  before_action :set_parent

  private
    def set_crumbs
      set_category
      if @category.present?
        @crumbs << [:"modules.gws/board", gws_board_topics_path]
        @crumbs << [@category.name, gws_board_category_topics_path]
      else
        @crumbs << [:"modules.gws/board", gws_board_topics_path]
      end
    end

    def set_category
      if params[:category].present?
        @category ||= Gws::Board::Category.site(@cur_site).where(id: params[:category]).first
      end
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, topic_id: params[:topic_id], parent_id: params[:parent_id] }
    end

    def pre_params
      { name: "Re: #{@parent.name}" }
    end

    def set_parent
      @topic  = @model.find params[:topic_id]
      @parent = @model.find params[:parent_id]
    end

  public
    def index
      if @category.present?
        redirect_to gws_board_category_topic_path(id: @topic.id)
      else
        redirect_to gws_board_topic_path(id: @topic.id)
      end
    end

    def show
      if @category.present?
        redirect_to gws_board_category_topic_path(id: @topic.id)
      else
        redirect_to gws_board_topic_path(id: @topic.id)
      end
    end
end
