class Sys::Auth::OpenIdConnectsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Auth::OpenIdConnect

  navi_view "sys/auth/main/navi"
  menu_view "sys/crud/menu"

  private
    def append_view_paths
      append_view_path "app/views/sys/auth/main/"
      super
    end

  public
    def create
      @item = @model.new get_params.merge(redirect_uri: sns_login_open_id_connect_callback_path)
      raise "403" unless @item.allowed?(:edit, @cur_user)
      render_create @item.save
    end
end
