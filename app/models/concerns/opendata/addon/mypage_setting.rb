module Opendata::Addon::MypageSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :dataset_workflow_route, class_name: "Workflow::Route"
    belongs_to :app_workflow_route, class_name: "Workflow::Route"
    belongs_to :idea_workflow_route, class_name: "Workflow::Route"

    permit_params :dataset_workflow_route_id
    permit_params :app_workflow_route_id
    permit_params :idea_workflow_route_id
  end
end
