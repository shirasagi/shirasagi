class Cms::CheckLinks::SiteSettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Site
  navi_view "cms/check_links/main/navi"
  menu_view "cms/crud/resource_menu"

  private

  def set_crumbs
    @crumbs << [t("modules.cms/check_links"), cms_check_links_path]
    @crumbs << [t("cms/check_links.site_setting"), action: :show]
  end

  public

  def set_item
    @item = @cur_site

    @addons = @item.addons.select { |item| item.klass == SS::Addon::CheckLinksSetting }
    @addon_basic_name = @addons.first.name
  end
end
