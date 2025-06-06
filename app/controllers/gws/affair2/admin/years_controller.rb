class Gws::Affair2::Admin::YearsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair2::PaidLeaveSetting

  navi_view "gws/affair2/admin/main/navi"

  helper_method :years_options

  private

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path ]
    @crumbs << [ t('modules.gws/affair2/admin/paid_leave_setting'), action: :index ]
  end

  def years_options
    @years_options ||= begin
      year = Time.zone.today.year
      ((year - @cur_site.attendance_management_year)..(year + 1)).to_a.map do |year|
        ["#{year}#{I18n.t("datetime.prompts.year")}", year]
      end
    end.reverse
  end

  public

  def index
  end
end
