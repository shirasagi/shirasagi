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
    @crumbs << [@cur_site.effective_schedule_personal_tab_label, gws_schedule_plans_path]
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

    todo_search = OpenStruct.new(params[:s])
    todo_search.category_id = nil if todo_search.category_id.present?

    @todos = Gws::Schedule::Todo.site(@cur_site).without_deleted.
      member(@cur_user).
      search(todo_search)

    @works = Gws::Workload::Work.site(@cur_site).without_deleted.
      member(@cur_user)
  end

  def download
    @s ||= OpenStruct.new(params[:s])
    @s[:encoding] ||= 'UTF-8'
    @s[:period] ||= 'period'
    @s[:start_at] ||= Time.zone.now.beginning_of_month
    @s[:end_at] ||= Time.zone.now.end_of_month

    if request.get? || request.head?
      return
    end

    # @items = Gws::Schedule::Plan.site(@cur_site).
    #   member(@cur_user).
    #   search(params[:s])

    safe_params = params.require(:s).permit(:encoding, :period, :start_at, :end_at)
    encoding = safe_params[:encoding]
    if safe_params[:period] == 'period'
      @items = @items.gte(end_at: safe_params[:start_at]) if safe_params[:start_at].present?
      @items = @items.lte(start_at: safe_params[:end_at]) if safe_params[:end_at].present?
    end
    filename = "gws_schedule_plans_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum(
      Gws::Schedule::PlanCsv::Exporter.enum_csv(@items, site: @cur_site, user: @cur_user, encoding: encoding, truncate: true),
      type: 'text/csv; charset=Shift_JIS', filename: filename
    )
  end
end
