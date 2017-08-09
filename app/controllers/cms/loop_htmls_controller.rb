class Cms::LoopHtmlsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::LoopHtml
  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("cms.loop_html"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
