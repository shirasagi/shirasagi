class Sys::Auth::SettingsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Auth::Setting

  navi_view "sys/auth/main/navi"
  menu_view "sys/crud/menu"

  private

  def set_item
    @item = @model.first_or_create
  end

  def append_view_paths
    append_view_path "app/views/sys/auth/main/"
    super
  end
end
