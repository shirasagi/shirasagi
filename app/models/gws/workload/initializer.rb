module Gws::Workload
  class Initializer
    Gws::Role.permission :use_gws_workload, module_name: 'gws/workload'

    Gws::Role.permission :edit_gws_workload_settings, module_name: 'gws/workload'

    Gws::Role.permission :read_other_gws_workload_works, module_name: 'gws/workload'
    Gws::Role.permission :read_private_gws_workload_works, module_name: 'gws/workload'
    Gws::Role.permission :edit_other_gws_workload_works, module_name: 'gws/workload'
    Gws::Role.permission :edit_private_gws_workload_works, module_name: 'gws/workload'
    Gws::Role.permission :delete_other_gws_workload_works, module_name: 'gws/workload'
    Gws::Role.permission :delete_private_gws_workload_works, module_name: 'gws/workload'
    Gws::Role.permission :trash_other_gws_workload_works, module_name: 'gws/workload'
    Gws::Role.permission :trash_private_gws_workload_works, module_name: 'gws/workload'

    Gws::Role.permission :use_gws_workload_overtimes, module_name: 'gws/workload'
    Gws::Role.permission :manage_gws_workload_overtimes, module_name: 'gws/workload'
    Gws::Role.permission :all_gws_workload_overtimes, module_name: 'gws/workload'

    Gws::Role.permission :read_other_gws_workload_graphs, module_name: 'gws/workload'
    Gws::Role.permission :read_private_gws_workload_graphs, module_name: 'gws/workload'

    Gws.module_usable :workload do |site, user|
      Gws::Workload.allowed?(:use, user, site: site)
    end
  end
end
