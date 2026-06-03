class Cms::Translate::SiteSettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Site
  navi_view "cms/translate/main/navi"
  menu_view "cms/crud/resource_menu"

  private

  def set_crumbs
    @crumbs << [t("translate.main"), cms_translate_main_path]
    @crumbs << [t("translate.site_setting"), action: :show]
  end

  public

  def set_item
    @item = @cur_site
  end
end
