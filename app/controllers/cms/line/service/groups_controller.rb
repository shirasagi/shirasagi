class Cms::Line::Service::GroupsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::Service::Group

  navi_view "cms/line/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.line_service"), cms_line_service_groups_path]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end
end
