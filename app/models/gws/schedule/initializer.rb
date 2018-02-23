module Gws::Schedule
  class Initializer
    Gws::User.include Gws::Schedule::UserSetting

    Gws::Role.permission :edit_gws_schedule_holidays, module_name: 'gws/schedule'

    Gws::Role.permission :read_other_gws_schedule_plans, module_name: 'gws/schedule'
    Gws::Role.permission :read_private_gws_schedule_plans, module_name: 'gws/schedule'
    Gws::Role.permission :edit_other_gws_schedule_plans, module_name: 'gws/schedule'
    Gws::Role.permission :edit_private_gws_schedule_plans, module_name: 'gws/schedule'
    Gws::Role.permission :delete_other_gws_schedule_plans, module_name: 'gws/schedule'
    Gws::Role.permission :delete_private_gws_schedule_plans, module_name: 'gws/schedule'
    Gws::Role.permission :trash_other_gws_schedule_plans, module_name: 'gws/schedule'
    Gws::Role.permission :trash_private_gws_schedule_plans, module_name: 'gws/schedule'

    Gws::Role.permission :read_other_gws_schedule_categories, module_name: 'gws/schedule'
    Gws::Role.permission :read_private_gws_schedule_categories, module_name: 'gws/schedule'
    Gws::Role.permission :edit_other_gws_schedule_categories, module_name: 'gws/schedule'
    Gws::Role.permission :edit_private_gws_schedule_categories, module_name: 'gws/schedule'
    Gws::Role.permission :delete_other_gws_schedule_categories, module_name: 'gws/schedule'
    Gws::Role.permission :delete_private_gws_schedule_categories, module_name: 'gws/schedule'

    Gws::Role.permission :read_other_gws_schedule_todos, module_name: 'gws/schedule'
    Gws::Role.permission :read_private_gws_schedule_todos, module_name: 'gws/schedule'
    Gws::Role.permission :edit_other_gws_schedule_todos, module_name: 'gws/schedule'
    Gws::Role.permission :edit_private_gws_schedule_todos, module_name: 'gws/schedule'
    Gws::Role.permission :delete_other_gws_schedule_todos, module_name: 'gws/schedule'
    Gws::Role.permission :delete_private_gws_schedule_todos, module_name: 'gws/schedule'
    Gws::Role.permission :trash_other_gws_schedule_todos, module_name: 'gws/schedule'
    Gws::Role.permission :trash_private_gws_schedule_todos, module_name: 'gws/schedule'
  end
end
