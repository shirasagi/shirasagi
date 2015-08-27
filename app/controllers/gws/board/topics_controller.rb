class Gws::Board::TopicsController < ApplicationController
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
      @items = @model.topic.order(descendants_updated: -1)
    end

    def show
      render file: "show_#{@item.mode}"
    end
end
