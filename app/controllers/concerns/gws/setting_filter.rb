module Gws::SettingFilter
  extend ActiveSupport::Concern

  included do
    prepend_view_path "app/views/gws/settings"
    menu_view "gws/crud/resource_menu"
    model Gws::Group
  end

  private
    def set_item
      @item = @cur_site
    end

    def set_crumbs
      #@crumbs << [:"gws.setting", gws_settings_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def show
      raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
      super
    end

    def edit
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      super
    end

    def update
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      super
    end
end
