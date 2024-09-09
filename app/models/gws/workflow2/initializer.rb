module Gws::Workflow2
  class Initializer
    Gws::Role.permission :use_gws_workflow2, module_name: 'gws/workflow2'

    Gws::Role.permission :read_other_gws_workflow2_routes, module_name: 'gws/workflow2'
    Gws::Role.permission :read_private_gws_workflow2_routes, module_name: 'gws/workflow2'
    Gws::Role.permission :edit_other_gws_workflow2_routes, module_name: 'gws/workflow2'
    Gws::Role.permission :edit_private_gws_workflow2_routes, module_name: 'gws/workflow2'
    Gws::Role.permission :delete_other_gws_workflow2_routes, module_name: 'gws/workflow2'
    Gws::Role.permission :delete_private_gws_workflow2_routes, module_name: 'gws/workflow2'
    Gws::Role.permission :public_readable_range_gws_workflow2_routes, module_name: 'gws/workflow2'

    Gws::Role.permission :read_other_gws_workflow2_files, module_name: 'gws/workflow2'
    # Gws::Role.permission :read_private_gws_workflow2_files, module_name: 'gws/workflow2'
    Gws::Role.permission :edit_other_gws_workflow2_files, module_name: 'gws/workflow2'
    # Gws::Role.permission :edit_private_gws_workflow2_files, module_name: 'gws/workflow2'
    Gws::Role.permission :delete_other_gws_workflow2_files, module_name: 'gws/workflow2'
    # Gws::Role.permission :delete_private_gws_workflow2_files, module_name: 'gws/workflow2'
    Gws::Role.permission :reroute_private_gws_workflow2_files, module_name: 'gws/workflow2'
    Gws::Role.permission :reroute_other_gws_workflow2_files, module_name: 'gws/workflow2'
    # Gws::Role.permission :trash_private_gws_workflow2_files, module_name: 'gws/workflow2'
    # Gws::Role.permission :trash_other_gws_workflow2_files, module_name: 'gws/workflow2'
    # Gws::Role.permission :agent_all_gws_workflow2_files, module_name: 'gws/workflow2'
    # Gws::Role.permission :agent_private_gws_workflow2_files, module_name: 'gws/workflow2'

    Gws::Role.permission :read_other_gws_workflow2_forms, module_name: 'gws/workflow2'
    Gws::Role.permission :read_private_gws_workflow2_forms, module_name: 'gws/workflow2'
    Gws::Role.permission :edit_other_gws_workflow2_forms, module_name: 'gws/workflow2'
    Gws::Role.permission :edit_private_gws_workflow2_forms, module_name: 'gws/workflow2'
    Gws::Role.permission :delete_other_gws_workflow2_forms, module_name: 'gws/workflow2'
    Gws::Role.permission :delete_private_gws_workflow2_forms, module_name: 'gws/workflow2'

    Gws::Role.permission :read_other_gws_workflow2_form_categories, module_name: 'gws/workflow2'
    Gws::Role.permission :read_private_gws_workflow2_form_categories, module_name: 'gws/workflow2'
    Gws::Role.permission :edit_other_gws_workflow2_form_categories, module_name: 'gws/workflow2'
    Gws::Role.permission :edit_private_gws_workflow2_form_categories, module_name: 'gws/workflow2'
    Gws::Role.permission :delete_other_gws_workflow2_form_categories, module_name: 'gws/workflow2'
    Gws::Role.permission :delete_private_gws_workflow2_form_categories, module_name: 'gws/workflow2'

    Gws::Role.permission :read_other_gws_workflow2_form_purposes, module_name: 'gws/workflow2'
    Gws::Role.permission :read_private_gws_workflow2_form_purposes, module_name: 'gws/workflow2'
    Gws::Role.permission :edit_other_gws_workflow2_form_purposes, module_name: 'gws/workflow2'
    Gws::Role.permission :edit_private_gws_workflow2_form_purposes, module_name: 'gws/workflow2'
    Gws::Role.permission :delete_other_gws_workflow2_form_purposes, module_name: 'gws/workflow2'
    Gws::Role.permission :delete_private_gws_workflow2_form_purposes, module_name: 'gws/workflow2'

    Gws.module_usable :workflow2 do |site, user|
      Gws::Workflow2.allowed?(:use, user, site: site)
    end
  end
end
