class Sys::Sso::SamlsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Sso::Saml

  navi_view "sys/sso/main/navi"
  menu_view "sys/crud/menu"

  private
    def append_view_paths
      append_view_path "app/views/sys/sso/main/"
      super
    end
end
