class Gws::Board::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Board::Post

  private
    def set_crumbs
      @crumbs << [:"modules.gws/board", gws_board_topics_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def index
      @items = @model.site(@cur_site).topic.
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).
        order(descendants_updated: -1).
        page(params[:page]).per(50)
    end

    def show
      render file: "show_#{@item.mode}"
    end
end
