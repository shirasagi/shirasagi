module Gws::UserSettingFilter
  extend ActiveSupport::Concern

  included do
    prepend_view_path "app/views/gws/settings"
    navi_view "gws/user_settings/navi"
    menu_view "gws/user_settings/menu"
    model Gws::User
  end

  private
    def set_item
      @item = @cur_user
    end

    def set_crumbs
      #@crumbs << [:"gws.setting", gws_settings_path]
    end

    def fix_params
      {}
    end

    def permit_fields
      [ in_schedule_tabs_group_ids: [],
        in_schedule_tabs_group_ids_all: [],
        in_schedule_tabs_custom_group_ids: [],
        in_schedule_tabs_custom_group_ids_all: [] ]
    end

  public
    def show
      render
    end

    def edit
      render
    end

    def update
      @item.attributes = get_params
      render_update @item.update
    end
end
