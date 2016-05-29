class Sys::Auth::Samls::MetadataController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Auth::Saml

  navi_view "sys/auth/main/navi"
  menu_view "sys/crud/menu"

  private
    def append_view_paths
      append_view_path "app/views/sys/auth/main/"
      super
    end

  public
    def show
      redirect_to sys_auth_saml_path
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)

      render_create @item.save
    end
end
