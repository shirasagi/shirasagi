class Gws::Affair::ShiftWork::ShiftRecordsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter

  model Gws::Affair::ShiftRecord

  navi_view "gws/affair/main/navi"

  before_action :deny
  before_action :set_cur_month
  before_action :set_user
  before_action :set_crumbs
  before_action :set_shift_calendar
  before_action :set_groups
  helper_method :group_options, :editable_shift_record?

  private

  # シフト勤務機能は利用停止
  def deny
    raise "403"
  end

  def fix_params
    { shift_calendar: @shift_calendar }
  end

  def editable_shift_record?
    %i[manage_private manage_all].find { |priv| Gws::Affair::ShiftRecord.allowed?(priv, @cur_user, site: @cur_site) }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("modules.gws/affair/shift_work/shift_calendar"), gws_affair_shift_work_shift_calendars_path ]
    @crumbs << [ @user.name, gws_affair_shift_work_shift_calendar_shift_records_path ]
  end

  def set_cur_month
    @cur_year = params[:year].to_i
    @cur_month = params[:month].to_i
    @cur_date = Time.zone.parse("#{@cur_year}/#{@cur_month}/01")
  end

  def set_user
    @user = Gws::User.find(params[:user])
  end

  def set_shift_calendar
    @shift_calendar = Gws::Affair::ShiftCalendar.find(params[:shift_calendar_id])
  end

  def set_groups
    if @model.allowed?(:aggregate_all, @cur_user, site: @cur_site)
      @groups = Gws::Group.in_group(@cur_site).active
    elsif @model.allowed?(:aggregate_private, @cur_user, site: @cur_site)
      @groups = Gws::Group.in_group(@cur_group).active
    else
      @groups = Gws::Group.none
    end

    @group = @groups.to_a.select { |group| group.id == params[:group_id].to_i }.first
    @group ||= @cur_group
  end

  public

  def index
  end

  def download
    raise "403" unless editable_shift_record?
    enum = @model.enum_csv(@shift_calendar, @cur_year)
    send_enum enum, type: 'text/csv; charset=Shift_JIS',
      filename: "shift_records_#{Time.zone.now.strftime("%Y_%m%d_%H%M")}.csv"
  end

  def import
    raise "403" unless editable_shift_record?
    @item = @model.new
    return if request.get? || request.head?

    @item.attributes = get_params
    result = @item.import_csv
    flash.now[:notice] = t("ss.notice.saved") if result
    render_create result, location: { action: :index }, render: { file: :import }
  end
end
