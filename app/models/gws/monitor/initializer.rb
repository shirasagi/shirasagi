module Gws::Monitor
  class Initializer
    Gws::Role.permission :read_other_gws_monitor_posts, module_name: 'gws/monitor'
    Gws::Role.permission :read_private_gws_monitor_posts, module_name: 'gws/monitor'
    Gws::Role.permission :edit_other_gws_monitor_posts, module_name: 'gws/monitor'
    Gws::Role.permission :edit_private_gws_monitor_posts, module_name: 'gws/monitor'
    Gws::Role.permission :delete_other_gws_monitor_posts, module_name: 'gws/monitor'
    Gws::Role.permission :delete_private_gws_monitor_posts, module_name: 'gws/monitor'
    Gws::Role.permission :trash_other_gws_monitor_posts, module_name: 'gws/monitor'
    Gws::Role.permission :trash_private_gws_monitor_posts, module_name: 'gws/monitor'

    Gws::Role.permission :read_other_gws_monitor_categories, module_name: 'gws/monitor'
    Gws::Role.permission :read_private_gws_monitor_categories, module_name: 'gws/monitor'
    Gws::Role.permission :edit_other_gws_monitor_categories, module_name: 'gws/monitor'
    Gws::Role.permission :edit_private_gws_monitor_categories, module_name: 'gws/monitor'
    Gws::Role.permission :delete_other_gws_monitor_categories, module_name: 'gws/monitor'
    Gws::Role.permission :delete_private_gws_monitor_categories, module_name: 'gws/monitor'
  end
end

