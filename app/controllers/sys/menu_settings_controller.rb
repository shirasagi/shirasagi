class Sys::MenuSettingsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Setting

  menu_view "sys/crud/resource_menu"

  private

  def set_crumbs
    @crumbs << [t("sys.menu_settings"), sys_menu_settings_path]
  end

  def set_item
    @item = @model.find_or_create_by({})
  end
end
