class Gws::Board::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  navi_view "gws/board/settings/navi"

  private
    def set_crumbs
      @crumbs << [:"modules.settings.gws/board", gws_board_setting_path]
    end
end
