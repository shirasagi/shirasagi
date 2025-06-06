class Gws::Affair2::Admin::PaidLeaveSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair2::PaidLeaveSetting

  navi_view "gws/affair2/admin/main/navi"

  before_action :set_year
  before_action :set_crumbs
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :soft_delete]

  private

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path ]
    @crumbs << [ t('modules.gws/affair2/admin/paid_leave_setting'), gws_affair2_admin_years_path ]
    @crumbs << [ "#{@year}#{t("datetime.prompts.year")}", action: :index ]
  end

  def set_year
    @year = params[:year].to_i
  end

  def pre_params
    { year: @year }
  end

  def fix_params
    { year: @year, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.site(@cur_site).
      where(year: @year).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s])
  end

  def download_template
    downloader = Gws::Affair2::PaidLeaveSettingDownloader.new(@cur_site, @year)
    enumerable = downloader.template_enum_csv(encoding: "UTF-8")
    send_enum enumerable, type: enumerable.content_type, filename: "paid_leave_settings_#{Time.zone.now.to_i}.csv"
  end

  def download_remind
    if request.get? || request.head?
      return
    end

    downloader = Gws::Affair2::PaidLeaveSettingDownloader.new(@cur_site, @year)
    enumerable = downloader.remind_enum_csv(encoding: "UTF-8")
    send_enum enumerable, type: enumerable.content_type, filename: "paid_leave_settings_#{Time.zone.now.to_i}.csv"
  end

  def import
    @item = Gws::Affair2::PaidLeaveSettingImporter.new
    @item.cur_site = @cur_site
    if request.get? || request.head?
      return
    end

    @item.attributes = params.require(:item).permit(:in_file)
    if @item.invalid?
      return
    end
    render_update @item.import, notice: t("ss.notice.imported"), location: { action: :index }, render: { template: :import }
  end
end
