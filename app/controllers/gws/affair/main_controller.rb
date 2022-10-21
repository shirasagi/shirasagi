class Gws::Affair::MainController < ApplicationController
  include Gws::BaseFilter
  include Gws::Affair::PermissionFilter

  def index
    if Gws::Attendance::TimeCard.allowed?(:use, @cur_user, site: @cur_site, permission_name: attendance_permission_name)
      redirect_to gws_affair_attendance_time_card_main_path
    elsif Gws::Affair::OvertimeFile.allowed?(:read, @cur_user, site: @cur_site)
      redirect_to gws_affair_overtime_files_path(state: "mine")
    elsif Gws::Affair::LeaveFile.allowed?(:read, @cur_user, site: @cur_site)
      redirect_to gws_affair_leave_files_path(state: "mine")
    else
      render
    end
  end
end
