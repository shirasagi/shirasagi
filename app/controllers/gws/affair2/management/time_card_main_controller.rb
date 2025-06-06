class Gws::Affair2::Management::TimeCardMainController < ApplicationController
  include Gws::BaseFilter

  def index
    today = @cur_site.calc_attendance_date(Time.zone.now)
    redirect_to gws_affair2_management_time_cards_path(year_month: today.strftime('%Y%m'), group: @cur_group)
  end
end
