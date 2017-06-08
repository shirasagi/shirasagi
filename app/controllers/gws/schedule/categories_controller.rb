class Gws::Schedule::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/schedule/settings/navi"

  model Gws::Schedule::Category

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/schedule/group_setting"), gws_schedule_setting_path]
    @crumbs << [t("mongoid.models.gws/schedule/group_setting/category"), gws_schedule_plans_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(_id: -1).
      page(params[:page]).per(50)
  end
end
