class Cms::Translate::SiteSettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Site
  navi_view "cms/translate/main/navi"
  menu_view "cms/crud/resource_menu"

  def set_item
    @item = @cur_site
  end
end
