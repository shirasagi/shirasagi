class Sys::Sso::OpenIdConnectsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::SSO::OpenIDConnect

  navi_view "sys/sso/main/navi"
  menu_view "sys/crud/menu"
end
