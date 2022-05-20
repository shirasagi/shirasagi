class Cms::Line::Service::FacilitySearch::CategoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::FacilitySearch::Category

  navi_view "cms/line/main/navi"

  before_action :set_hook

  private

  def set_hook
    @hook = Cms::Line::Service::Hook::Base.find(params[:hook_id])
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user, hook: @hook }
  end

  def set_crumbs
    @crumbs << [t("cms.line_service"), cms_line_service_groups_path]
    @crumbs << [t("cms.line_facility_search_category"), { action: :index }]
  end

  def set_items
    @items = @hook.categories
  end
end
