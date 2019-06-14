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
    Gws::Role.permission :use_private_gws_schedule_plans, module_name: 'gws/schedule'

    Gws::Role.permission :read_other_gws_schedule_categories, module_name: 'gws/schedule'
    Gws::Role.permission :read_private_gws_schedule_categories, module_name: 'gws/schedule'
    Gws::Role.permission :edit_other_gws_schedule_categories, module_name: 'gws/schedule'
    Gws::Role.permission :edit_private_gws_schedule_categories, module_name: 'gws/schedule'
    Gws::Role.permission :delete_other_gws_schedule_categories, module_name: 'gws/schedule'
    Gws::Role.permission :delete_private_gws_schedule_categories, module_name: 'gws/schedule'

    Gws::Role.permission :read_other_gws_schedule_todos, module_name: 'gws/schedule/todo'
    Gws::Role.permission :read_private_gws_schedule_todos, module_name: 'gws/schedule/todo'
    Gws::Role.permission :edit_other_gws_schedule_todos, module_name: 'gws/schedule/todo'
    Gws::Role.permission :edit_private_gws_schedule_todos, module_name: 'gws/schedule/todo'
    Gws::Role.permission :delete_other_gws_schedule_todos, module_name: 'gws/schedule/todo'
    Gws::Role.permission :delete_private_gws_schedule_todos, module_name: 'gws/schedule/todo'
    Gws::Role.permission :trash_other_gws_schedule_todos, module_name: 'gws/schedule/todo'
    Gws::Role.permission :trash_private_gws_schedule_todos, module_name: 'gws/schedule/todo'
    Gws::Role.permission :use_private_gws_schedule_todos, module_name: 'gws/schedule/todo'

    Gws::Role.permission :read_other_gws_schedule_todo_categories, module_name: 'gws/schedule/todo'
    Gws::Role.permission :read_private_gws_schedule_todo_categories, module_name: 'gws/schedule/todo'
    Gws::Role.permission :edit_other_gws_schedule_todo_categories, module_name: 'gws/schedule/todo'
    Gws::Role.permission :edit_private_gws_schedule_todo_categories, module_name: 'gws/schedule/todo'
    Gws::Role.permission :delete_other_gws_schedule_todo_categories, module_name: 'gws/schedule/todo'
    Gws::Role.permission :delete_private_gws_schedule_todo_categories, module_name: 'gws/schedule/todo'

    Gws.module_usable :schedule do |site, user|
      Gws::Schedule::Plan.allowed?(:use, user, site: site) || user.gws_role_permit_any?(site, :use_private_gws_facility_plans)
    end

    Gws.module_usable :todo do |site, user|
      Gws::Schedule::Todo.allowed?(:use, user, site: site)
    end

    Gws.module_usable :reminder do |site, user|
      Gws.module_usable?(:schedule, site, user) || Gws.module_usable?(:todo, site, user)
    end
  end
end
