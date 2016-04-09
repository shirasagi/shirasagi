class Sys::Auth::SamlsController < ApplicationController
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
end
