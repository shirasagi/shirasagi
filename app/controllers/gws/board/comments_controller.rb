class Gws::Board::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Board::Post

  before_action :set_parent

  private
    def set_crumbs
      @crumbs << [:"modules.gws/board", gws_board_topics_path]
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
      redirect_to gws_board_topic_path(id: @topic.id)
    end

    def show
      redirect_to gws_board_topic_path(id: @topic.id)
    end
end
