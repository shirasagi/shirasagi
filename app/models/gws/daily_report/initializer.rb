module Gws::DailyReport
  class Initializer
    Gws::Role.permission :use_gws_daily_report_reports, module_name: 'gws/daily_report'
    Gws::Role.permission :edit_gws_daily_report_reports, module_name: 'gws/daily_report'
    Gws::Role.permission :manage_private_gws_daily_report_reports, module_name: 'gws/daily_report'
    Gws::Role.permission :manage_all_gws_daily_report_reports, module_name: 'gws/daily_report'
    Gws::Role.permission :access_gws_daily_report_reports, module_name: 'gws/daily_report'

    Gws::Role.permission :read_other_gws_daily_report_forms, module_name: 'gws/daily_report'
    Gws::Role.permission :read_private_gws_daily_report_forms, module_name: 'gws/daily_report'
    Gws::Role.permission :edit_other_gws_daily_report_forms, module_name: 'gws/daily_report'
    Gws::Role.permission :edit_private_gws_daily_report_forms, module_name: 'gws/daily_report'
    Gws::Role.permission :delete_other_gws_daily_report_forms, module_name: 'gws/daily_report'
    Gws::Role.permission :delete_private_gws_daily_report_forms, module_name: 'gws/daily_report'

    Gws::Role.permission :read_other_gws_daily_report_comments, module_name: 'gws/daily_report'
    Gws::Role.permission :read_private_gws_daily_report_comments, module_name: 'gws/daily_report'
    Gws::Role.permission :edit_other_gws_daily_report_comments, module_name: 'gws/daily_report'
    Gws::Role.permission :edit_private_gws_daily_report_comments, module_name: 'gws/daily_report'
    Gws::Role.permission :delete_other_gws_daily_report_comments, module_name: 'gws/daily_report'
    Gws::Role.permission :delete_private_gws_daily_report_comments, module_name: 'gws/daily_report'

    Gws.module_usable :daily_report do |site, user|
      Gws::DailyReport.allowed?(:use, user, site: site)
    end
  end
end
