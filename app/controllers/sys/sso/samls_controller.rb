class Sys::Sso::SamlsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::SSO::SAML

  navi_view "sys/sso/main/navi"
  menu_view "sys/crud/menu"
end
