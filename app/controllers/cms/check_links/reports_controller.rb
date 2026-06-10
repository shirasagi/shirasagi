class Cms::CheckLinks::ReportsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::CheckLinks::Report

  navi_view "cms/check_links/main/navi"
  menu_view nil

  private

  def set_crumbs
    @crumbs << [t("modules.cms/check_links"), cms_check_links_path]
    @crumbs << [t("cms/check_links.reports"), action: :index]
  end
end
