module Gws::Affair
  class Initializer
    Gws::Role.permission :use_gws_affair, module_name: 'gws/affair'

    # timecard
    Gws::Role.permission :use_gws_affair_attendance_time_cards, module_name: 'gws/affair'
    Gws::Role.permission :edit_gws_affair_attendance_time_cards, module_name: 'gws/affair'
    Gws::Role.permission :manage_private_gws_affair_attendance_time_cards, module_name: 'gws/affair'
    Gws::Role.permission :manage_all_gws_affair_attendance_time_cards, module_name: 'gws/affair'
    Gws::Role.permission :aggregate_private_gws_affair_attendance_time_cards, module_name: 'gws/affair'
    Gws::Role.permission :aggregate_all_gws_affair_attendance_time_cards, module_name: 'gws/affair'

    # overtime file
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
    # overtime file aggregate
    Gws::Role.permission :use_aggregate_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :manage_aggregate_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :all_aggregate_gws_affair_overtime_files, module_name: 'gws/affair'

    # leave file
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
    # leave aggregate
    Gws::Role.permission :use_aggregate_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :manage_aggregate_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :all_aggregate_gws_affair_leave_files, module_name: 'gws/affair'

    # shift calendar
    Gws::Role.permission :use_gws_affair_shift_calendars, module_name: 'gws/affair'
    Gws::Role.permission :manage_private_gws_affair_shift_calendars, module_name: 'gws/affair'
    Gws::Role.permission :manage_all_gws_affair_shift_calendars, module_name: 'gws/affair'

    # affair settings
    Gws::Role.permission :edit_gws_affair_duty_settings, module_name: 'gws/affair'
    Gws::Role.permission :edit_gws_affair_capital_years, module_name: 'gws/affair'
    Gws::Role.permission :edit_gws_affair_special_leaves, module_name: 'gws/affair'

    Gws.module_usable :affair do |site, user|
      Gws::Affair.allowed?(:use, user, site: site)
    end
  end
end
