class Gws::Workload::WorksController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workload::YearFilter
  include Gws::Workload::GroupFilter
  include Gws::Workload::WorkFilter
  include Gws::Workload::CalendarFilter
  include Gws::Workload::NotificationFilter

  navi_view "gws/workload/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workload_label || I18n.t('modules.gws/workload'), gws_workload_main_path]
    @crumbs << [I18n.t("gws/workload.tabs.work"), url_for(action: :index) ]
  end

  def set_items
    @items = @model.site(@cur_site).without_deleted
    @items = @items.member(@cur_user)
    @items = @items.search(@s).
      page(params[:page]).per(50).
      custom_order(params.dig(:s, :sort) || 'due_date')
  end
end
