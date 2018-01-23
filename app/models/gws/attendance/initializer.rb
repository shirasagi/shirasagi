module Gws::Attendance
  class Initializer
    Gws::Role.permission :use_gws_attendance_time_cards, module_name: 'gws/attendance'
    Gws::Role.permission :edit_gws_attendance_time_cards, module_name: 'gws/attendance'
    Gws::Role.permission :manage_private_gws_attendance_time_cards, module_name: 'gws/attendance'
    Gws::Role.permission :manage_all_gws_attendance_time_cards, module_name: 'gws/attendance'
  end
end
