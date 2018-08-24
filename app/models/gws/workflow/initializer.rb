module Gws::Workflow
  class Initializer
    Gws::Role.permission :read_other_gws_workflow_routes, module_name: 'gws/workflow'
    Gws::Role.permission :read_private_gws_workflow_routes, module_name: 'gws/workflow'
    Gws::Role.permission :edit_other_gws_workflow_routes, module_name: 'gws/workflow'
    Gws::Role.permission :edit_private_gws_workflow_routes, module_name: 'gws/workflow'
    Gws::Role.permission :delete_other_gws_workflow_routes, module_name: 'gws/workflow'
    Gws::Role.permission :delete_private_gws_workflow_routes, module_name: 'gws/workflow'

    Gws::Role.permission :read_other_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :read_private_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :edit_other_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :edit_private_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :delete_other_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :delete_private_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :approve_private_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :approve_other_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :reroute_private_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :reroute_other_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :trash_private_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :trash_other_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :agent_all_gws_workflow_files, module_name: 'gws/workflow'
    Gws::Role.permission :agent_private_gws_workflow_files, module_name: 'gws/workflow'

    Gws::Role.permission :read_other_gws_workflow_forms, module_name: 'gws/workflow'
    Gws::Role.permission :read_private_gws_workflow_forms, module_name: 'gws/workflow'
    Gws::Role.permission :edit_other_gws_workflow_forms, module_name: 'gws/workflow'
    Gws::Role.permission :edit_private_gws_workflow_forms, module_name: 'gws/workflow'
    Gws::Role.permission :delete_other_gws_workflow_forms, module_name: 'gws/workflow'
    Gws::Role.permission :delete_private_gws_workflow_forms, module_name: 'gws/workflow'
  end
end
