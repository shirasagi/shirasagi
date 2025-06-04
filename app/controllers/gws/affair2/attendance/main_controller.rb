class Gws::Affair2::Attendance::MainController < ApplicationController
  include Gws::BaseFilter
  include Gws::Affair2::BaseFilter

  def index
    redirect_to gws_affair2_attendance_time_cards_path(year_month: @attendance_year_month)
  end
end
