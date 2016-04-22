module Gws::UserSettingFilter
  extend ActiveSupport::Concern
  include Gws::SettingFilter

  included do
    prepend_view_path "app/views/gws/settings"
    navi_view "gws/user_settings/navi"
    menu_view "gws/crud/resource_menu"
    model Gws::User
  end

  private
    def set_item
      @item = @cur_user
    end
end
