class Gws::Board::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  navi_view "gws/board/settings/navi"

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/board/group_setting", gws_board_setting_path]
    end
end
