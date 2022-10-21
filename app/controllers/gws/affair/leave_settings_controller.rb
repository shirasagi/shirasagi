class Gws::Affair::LeaveSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter

  model Gws::Affair::LeaveSetting

  navi_view "gws/affair/main/navi"

  before_action :set_year

  private

  def set_crumbs
    set_year
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [@cur_year.name, gws_affair_capital_years_path]
    @crumbs << [t('modules.gws/affair/leave_setting'), gws_affair_leave_settings_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, year: @cur_year }
  end

  def set_year
    @cur_year ||= Gws::Affair::CapitalYear.site(@cur_site).find(params[:year])
  end

  def set_items
    @items = @cur_year.yearly_leave_settings
  end

  public

  def index
    set_items
    @items = @items.allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    @items = @items.allow(:read, @cur_user, site: @cur_site)

    enum_csv = @items.enum_csv
    send_enum(enum_csv,
      type: 'text/csv; charset=Shift_JIS',
      filename: "leave_settings_#{Time.zone.now.to_i}.csv"
    )
  end

  def download_yearly
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @item = @cur_year.leave_setting_day_count(@cur_user)
    return if request.get? || request.head?

    enum_csv = @item.enum_csv
    send_enum(enum_csv,
      type: 'text/csv; charset=Shift_JIS',
      filename: "leave_settings_#{Time.zone.now.to_i}.csv"
    )
  end

  def download_member
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @item = @cur_year.leave_setting_member(@cur_user)
    enum_csv = @item.enum_csv
    send_enum(enum_csv,
      type: 'text/csv; charset=Shift_JIS',
      filename: "leave_settings_#{Time.zone.now.to_i}.csv"
    )
  end

  def import
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    return if request.get? || request.head?
    @item = @model.new get_params
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { file: :import }
  end

  def import_member
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    return if request.get? || request.head?

    @item = @cur_year.leave_setting_member(@cur_user)
    @item.attributes = get_params

    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :import_member }, render: { file: :import_member }
  end
end
