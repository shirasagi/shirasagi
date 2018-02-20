class Gws::Schedule::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  navi_view 'gws/schedule/main/navi'

  menu_view 'gws/crud/menu'

  def index
    @items = Gws::Schedule::Plan.site(@cur_site).only_deleted.
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(start_at: -1).
      page(params[:page]).per(50)
  end

  def restore
    set_item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.deleted = nil

    render_opts = {}
    render_opts[:location] = gws_schedule_plan_path(id: @item)
    render_opts[:render] = { file: :restore }
    render_opts[:notice] = t('ss.notice.restored')

    render_update @item.save, render_opts
  end
end
