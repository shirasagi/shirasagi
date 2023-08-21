class Gws::Workload::Graph::UserSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workload::YearFilter
  include Gws::Workload::GroupFilter

  model Gws::Workload::Graph::UserSetting

  navi_view "gws/workload/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workload_label || I18n.t('modules.gws/workload'), gws_workload_main_path]
    @crumbs << [I18n.t('mongoid.models.gws/workload/graph/user_setting'), { action: :index }]
  end

  def dropdowns
    %w(year group)
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.create_settings(@users, site_id: @cur_site.id, group_id: @group.id).
      search(params[:s]).
      allow(:read, @cur_user, site: @cur_site).
      page(params[:page]).per(50)
  end
end
