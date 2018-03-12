class Gws::Schedule::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  navi_view 'gws/schedule/main/navi'

  menu_view 'gws/crud/menu'

  private

  def set_items
    @items = Gws::Schedule::Plan.site(@cur_site).only_deleted.
      allow(:trash, @cur_user, site: @cur_site).
      search(params[:s])
  end

  public

  def index
    @items = @items.
      order_by(start_at: -1).
      page(params[:page]).per(50)
  end
end
