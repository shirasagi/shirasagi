module Gws::Affair
  class Initializer
    Gws::Role.permission :use_gws_affair_attendance_time_cards, module_name: 'gws/affair'
    Gws::Role.permission :edit_gws_affair_attendance_time_cards, module_name: 'gws/affair'
    Gws::Role.permission :manage_private_affair_gws_attendance_time_cards, module_name: 'gws/affair'
    Gws::Role.permission :manage_all_gws_affair_attendance_time_cards, module_name: 'gws/affair'

    Gws::Role.permission :read_gws_affair_duty_hours, module_name: 'gws/affair'
    Gws::Role.permission :edit_gws_affair_duty_hours, module_name: 'gws/affair'
    Gws::Role.permission :delete_gws_affair_duty_hours, module_name: 'gws/affair'

    Gws::Role.permission :read_other_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :read_private_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :edit_other_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :edit_private_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :delete_other_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :delete_private_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :approve_private_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :approve_other_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :reroute_private_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :reroute_other_gws_affair_overtime_files, module_name: 'gws/affair'

    Gws::Role.permission :read_other_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :read_private_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :edit_other_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :edit_private_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :delete_other_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :delete_private_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :approve_private_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :approve_other_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :reroute_private_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :reroute_other_gws_affair_leave_files, module_name: 'gws/affair'

    Gws::Role.permission :use_gws_affair_shift_calendars, module_name: 'gws/affair'
    Gws::Role.permission :manage_private_gws_affair_shift_calendars, module_name: 'gws/affair'
    Gws::Role.permission :manage_all_gws_affair_shift_calendars, module_name: 'gws/affair'

    Gws::Role.permission :read_gws_affair_special_leaves, module_name: 'gws/affair'
    Gws::Role.permission :edit_gws_affair_special_leaves, module_name: 'gws/affair'
    Gws::Role.permission :delete_gws_affair_special_leaves, module_name: 'gws/affair'

    Gws::Role.permission :read_gws_affair_capitals, module_name: 'gws/affair'
    Gws::Role.permission :edit_gws_affair_capitals, module_name: 'gws/affair'
    Gws::Role.permission :delete_gws_affair_capitals, module_name: 'gws/affair'

    Gws::Role.permission :use_gws_affair_overtime_aggregate, module_name: 'gws/affair'
    Gws::Role.permission :manage_gws_affair_overtime_aggregate, module_name: 'gws/affair'
    Gws::Role.permission :all_gws_affair_overtime_aggregate, module_name: 'gws/affair'

    Gws::Role.permission :read_other_gws_affair_leave_settings, module_name: 'gws/affair'
    Gws::Role.permission :read_private_gws_affair_leave_settings, module_name: 'gws/affair'
    Gws::Role.permission :edit_other_gws_affair_leave_settings, module_name: 'gws/affair'
    Gws::Role.permission :edit_private_gws_affair_leave_settings, module_name: 'gws/affair'
    Gws::Role.permission :delete_other_gws_affair_leave_settings, module_name: 'gws/affair'
    Gws::Role.permission :delete_private_gws_affair_leave_settings, module_name: 'gws/affair'

    Gws::Role.permission :use_gws_affair_leave_aggregate, module_name: 'gws/affair'
    Gws::Role.permission :manage_gws_affair_leave_aggregate, module_name: 'gws/affair'
    Gws::Role.permission :all_gws_affair_leave_aggregate, module_name: 'gws/affair'

    #Gws.module_usable :affair do |site, user|
    #  Gws::Attendance.allowed?(:use, user, site: site)
    #end
  end
end
