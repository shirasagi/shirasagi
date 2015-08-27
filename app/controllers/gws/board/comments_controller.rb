class Gws::Board::CommentsController < ApplicationController
  include Gws::BaseFilter
  include SS::CrudFilter

  model Gws::Board::Post

  private
    def set_crumbs
      @crumbs << [:"modules.gws_board", gws_board_topics_path]
    end

    def fix_params
      { user: @cur_user }
    end

  public
    def index
      @parent = @model.find(params[:parent_id])
      redirect_to gws_board_topic_path(id: @parent.topic_id)
    end

    def new
      @parent = @model.find(params[:parent_id])
      super
    end

    def edit
      @parent = @model.find(params[:parent_id])
      super
    end

    def create
      @item = @model.new get_params.merge({parent_id: params[:parent_id]})
      @parent = @item.parent
      render_create @item.save, location: { controller: 'gws/board/topics', action: :show, id: @item.topic_id }
    end
end
