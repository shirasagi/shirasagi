module Gws::Report
  class Initializer
    Gws::Role.permission :use_gws_report, module_name: 'gws/report'

    Gws::Role.permission :read_other_gws_report_files, module_name: 'gws/report'
    Gws::Role.permission :read_private_gws_report_files, module_name: 'gws/report'
    Gws::Role.permission :edit_other_gws_report_files, module_name: 'gws/report'
    Gws::Role.permission :edit_private_gws_report_files, module_name: 'gws/report'
    Gws::Role.permission :delete_other_gws_report_files, module_name: 'gws/report'
    Gws::Role.permission :delete_private_gws_report_files, module_name: 'gws/report'
    Gws::Role.permission :trash_other_gws_report_files, module_name: 'gws/report'
    Gws::Role.permission :trash_private_gws_report_files, module_name: 'gws/report'

    Gws::Role.permission :read_other_gws_report_forms, module_name: 'gws/report'
    Gws::Role.permission :read_private_gws_report_forms, module_name: 'gws/report'
    Gws::Role.permission :edit_other_gws_report_forms, module_name: 'gws/report'
    Gws::Role.permission :edit_private_gws_report_forms, module_name: 'gws/report'
    Gws::Role.permission :delete_other_gws_report_forms, module_name: 'gws/report'
    Gws::Role.permission :delete_private_gws_report_forms, module_name: 'gws/report'

    Gws::Role.permission :read_other_gws_report_categories, module_name: 'gws/report'
    Gws::Role.permission :read_private_gws_report_categories, module_name: 'gws/report'
    Gws::Role.permission :edit_other_gws_report_categories, module_name: 'gws/report'
    Gws::Role.permission :edit_private_gws_report_categories, module_name: 'gws/report'
    Gws::Role.permission :delete_other_gws_report_categories, module_name: 'gws/report'
    Gws::Role.permission :delete_private_gws_report_categories, module_name: 'gws/report'

    Gws.module_usable :report do |site, user|
      Gws::Report.allowed?(:use, user, site: site)
    end
  end
end
