module Workflow
  class Initializer
    Cms::Role.permission :read_other_workflow_routes
    Cms::Role.permission :read_private_workflow_routes
    Cms::Role.permission :edit_other_workflow_routes
    Cms::Role.permission :edit_private_workflow_routes
    Cms::Role.permission :delete_other_workflow_routes
    Cms::Role.permission :delete_private_workflow_routes
  end
end
