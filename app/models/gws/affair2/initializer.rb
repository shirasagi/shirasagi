module Gws::Affair2
  class Initializer
    # time_cards
    Gws::Role.permission :use_gws_affair2_attendance_time_cards, module_name: 'gws/affair2'
    Gws::Role.permission :edit_gws_affair2_attendance_time_cards, module_name: 'gws/affair2'
    Gws::Role.permission :manage_all_gws_affair2_attendance_time_cards, module_name: 'gws/affair2'
    Gws::Role.permission :manage_sub_gws_affair2_attendance_time_cards, module_name: 'gws/affair2'

    # groups
    Gws::Role.permission :use_private_gws_affair2_attendance_groups, module_name: 'gws/affair2'
    Gws::Role.permission :use_sub_gws_affair2_attendance_groups, module_name: 'gws/affair2'
    Gws::Role.permission :use_all_gws_affair2_attendance_groups, module_name: 'gws/affair2'

    # time_card_settings
    Gws::Role.permission :format_gws_affair2_attendance_time_cards, module_name: 'gws/affair2'

    # overtime_workday_files
    Gws::Role.permission :read_other_gws_affair2_overtime_workday_files, module_name: 'gws/affair2'
    Gws::Role.permission :read_private_gws_affair2_overtime_workday_files, module_name: 'gws/affair2'
    Gws::Role.permission :edit_other_gws_affair2_overtime_workday_files, module_name: 'gws/affair2'
    Gws::Role.permission :edit_private_gws_affair2_overtime_workday_files, module_name: 'gws/affair2'
    Gws::Role.permission :delete_other_gws_affair2_overtime_workday_files, module_name: 'gws/affair2'
    Gws::Role.permission :delete_private_gws_affair2_overtime_workday_files, module_name: 'gws/affair2'
    Gws::Role.permission :approve_other_gws_affair2_overtime_workday_files, module_name: 'gws/affair2'
    Gws::Role.permission :approve_private_gws_affair2_overtime_workday_files, module_name: 'gws/affair2'
    Gws::Role.permission :reroute_other_gws_affair2_overtime_workday_files, module_name: 'gws/affair2'
    Gws::Role.permission :reroute_private_gws_affair2_overtime_workday_files, module_name: 'gws/affair2'

    # overtime_holiday_files
    Gws::Role.permission :read_other_gws_affair2_overtime_holiday_files, module_name: 'gws/affair2'
    Gws::Role.permission :read_private_gws_affair2_overtime_holiday_files, module_name: 'gws/affair2'
    Gws::Role.permission :edit_other_gws_affair2_overtime_holiday_files, module_name: 'gws/affair2'
    Gws::Role.permission :edit_private_gws_affair2_overtime_holiday_files, module_name: 'gws/affair2'
    Gws::Role.permission :delete_other_gws_affair2_overtime_holiday_files, module_name: 'gws/affair2'
    Gws::Role.permission :delete_private_gws_affair2_overtime_holiday_files, module_name: 'gws/affair2'
    Gws::Role.permission :approve_other_gws_affair2_overtime_holiday_files, module_name: 'gws/affair2'
    Gws::Role.permission :approve_private_gws_affair2_overtime_holiday_files, module_name: 'gws/affair2'
    Gws::Role.permission :reroute_other_gws_affair2_overtime_holiday_files, module_name: 'gws/affair2'
    Gws::Role.permission :reroute_private_gws_affair2_overtime_holiday_files, module_name: 'gws/affair2'

    # leave_files
    Gws::Role.permission :read_other_gws_affair2_leave_files, module_name: 'gws/affair2'
    Gws::Role.permission :read_private_gws_affair2_leave_files, module_name: 'gws/affair2'
    Gws::Role.permission :edit_other_gws_affair2_leave_files, module_name: 'gws/affair2'
    Gws::Role.permission :edit_private_gws_affair2_leave_files, module_name: 'gws/affair2'
    Gws::Role.permission :delete_other_gws_affair2_leave_files, module_name: 'gws/affair2'
    Gws::Role.permission :delete_private_gws_affair2_leave_files, module_name: 'gws/affair2'
    Gws::Role.permission :approve_other_gws_affair2_leave_files, module_name: 'gws/affair2'
    Gws::Role.permission :approve_private_gws_affair2_leave_files, module_name: 'gws/affair2'
    Gws::Role.permission :reroute_other_gws_affair2_leave_files, module_name: 'gws/affair2'
    Gws::Role.permission :reroute_private_gws_affair2_leave_files, module_name: 'gws/affair2'

    # achieve
    Gws::Role.permission :use_private_gws_affair2_overtime_achieves, module_name: 'gws/affair2'
    Gws::Role.permission :use_sub_gws_affair2_overtime_achieves, module_name: 'gws/affair2'
    Gws::Role.permission :use_all_gws_affair2_overtime_achieves, module_name: 'gws/affair2'
    Gws::Role.permission :use_private_gws_affair2_leave_achieves, module_name: 'gws/affair2'
    Gws::Role.permission :use_sub_gws_affair2_leave_achieves, module_name: 'gws/affair2'
    Gws::Role.permission :use_all_gws_affair2_leave_achieves, module_name: 'gws/affair2'

    # aggregation
    Gws::Role.permission :use_gws_affair2_aggregations, module_name: 'gws/affair2'

    # settings
    Gws::Role.permission :use_gws_affair2_admin_settings, module_name: 'gws/affair2'

    Gws.module_usable :affair2 do |site, user|
      Gws::Affair2::Attendance.allowed?(:use, user, site: site)
    end
  end
end
