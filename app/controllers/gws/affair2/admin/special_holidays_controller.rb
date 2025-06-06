class Gws::Affair2::Admin::SpecialHolidaysController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair2::SpecialHoliday

  navi_view "gws/affair2/admin/main/navi"

  before_action :set_year

  private

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path ]
    @crumbs << [ t('modules.gws/affair2/admin/special_holiday'), action: :index ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_year
    @cur_year = Time.zone.now.year
    @year = params[:year].to_i
    @year_name ||= "#{@year}#{I18n.t("datetime.prompts.year")}"
    @years ||= begin
      years = ((@cur_year - @cur_site.attendance_management_year)..(@cur_year + 1))
      years = years.map { |i| { _id: i, name: "#{i}#{I18n.t("datetime.prompts.year")}", trailing_name: i.to_s } }
      years.reverse
    end
  end

  public

  def index
    @items = @model.site(@cur_site).and_year(@year).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s])
  end

  def main
    redirect_to url_for({ action: :index, year: Time.zone.now.year })
  end
end
