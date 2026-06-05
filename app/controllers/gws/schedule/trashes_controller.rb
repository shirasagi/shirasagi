class Gws::Schedule::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  navi_view 'gws/schedule/main/navi'

  menu_view 'gws/crud/menu'

  self.destroy_notification_actions = []
  self.destroy_all_notification_actions = []

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label.presence || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('gws/schedule.navi.trash'), action: :index]
  end

  def set_items
    @items ||= begin
      Gws::Schedule::Plan.site(@cur_site).only_deleted.
        allow(:trash, @cur_user, site: @cur_site)
    end
  end

  public

  def index
    @items = @items.
      search(params[:s]).
      order_by(start_at: -1).
      page(params[:page]).per(50)
  end
end
