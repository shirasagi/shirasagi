module Gws::Attendance
  class Initializer
    Gws::Role.permission :use_gws_attendance_time_cards, module_name: 'gws/attendance'
    Gws::Role.permission :manage_gws_attendance_time_cards, module_name: 'gws/attendance'
  end
end
