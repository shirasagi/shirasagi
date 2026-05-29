class Cms::SourceCleaner::SiteSettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Site
  navi_view "cms/source_cleaner/main/navi"
  menu_view "cms/crud/resource_menu"

  private

  def set_crumbs
    @crumbs << [t("cms.source_cleaner"), cms_source_cleaner_main_path]
    @crumbs << [t("cms.site_setting"), action: :show]
  end

  public

  def set_item
    @item = @cur_site
  end
end
