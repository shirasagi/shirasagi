class Cms::CheckLinks::IgnoreUrlsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::CheckLinks::IgnoreUrl

  navi_view "cms/check_links/main/navi"

  private

  def set_crumbs
    @crumbs << [t("modules.cms/check_links"), cms_check_links_path]
    @crumbs << [t("cms/check_links.ignore_urls"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
