class Gws::Board::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/board/settings/navi"

  model Gws::Board::Category

  private
    def set_crumbs
      @crumbs << [:"modules.settings.gws/board", gws_board_setting_path]
      @crumbs << [:"modules.settings.gws/board/category", gws_board_topics_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
