class Sys::Auth::OpenIdConnects::DiscoveryController < ApplicationController
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
    def show
      redirect_to sys_auth_open_id_connect_path
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)

      # result = @item.save
      # location = @item.id ? sys_auth_open_id_connect_path(id: @item.id) : nil
      # render_create result, location: location
      render_create @item.save
    end
end
