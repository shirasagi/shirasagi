class Gws::Schedule::PlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  before_action :set_download_url, only: :index

  navi_view "gws/schedule/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('gws/schedule.tabs.personal'), gws_schedule_plans_path]
  end

  def set_download_url
    @download_url = url_for(action: :download)
  end

  public

  def index
    return render if params[:format] != 'json'

    # @items = Gws::Schedule::Plan.site(@cur_site).
    #   member(@cur_user).
    #   search(params[:s])
  end

  def events
    # @items = Gws::Schedule::Plan.site(@cur_site).without_deleted.
    #   member(@cur_user).
    #   search(params[:s])

    @todos = Gws::Schedule::Todo.site(@cur_site).without_deleted.
      member(@cur_user).
      search(params[:s])
  end

  def download
    # @items = Gws::Schedule::Plan.site(@cur_site).
    #   member(@cur_user).
    #   search(params[:s])

    filename = "gws_schedule_plans_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum(
      Gws::Schedule::PlanCsv::Exporter.enum_csv(@items, site: @cur_site, user: @cur_user),
      type: 'text/csv; charset=Shift_JIS', filename: filename
    )
  end
end
