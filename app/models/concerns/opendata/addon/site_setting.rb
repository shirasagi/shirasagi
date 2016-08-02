module Opendata::Addon::SiteSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :dataset_workflow_route, class_name: "Workflow::Route"
    belongs_to :app_workflow_route, class_name: "Workflow::Route"
    belongs_to :idea_workflow_route, class_name: "Workflow::Route"
    field :dataset_state, type: String, default: 'enabled'
    field :app_state, type: String, default: 'enabled'
    field :idea_state, type: String, default: 'enabled'

    permit_params :dataset_workflow_route_id
    permit_params :app_workflow_route_id
    permit_params :idea_workflow_route_id
    permit_params :dataset_state, :app_state, :idea_state

    validates :dataset_state, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :app_state, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :idea_state, inclusion: { in: %w(enabled disabled), allow_blank: true }
  end

  def dataset_state_options
    %w(enabled disabled).map do |v|
      [ I18n.t("views.options.state.#{v}"), v ]
    end
  end
  alias app_state_options dataset_state_options
  alias idea_state_options dataset_state_options

  def dataset_disabled?
    dataset_state == 'disabled'
  end

  def dataset_enabled?
    !dataset_disabled?
  end

  def app_disabled?
    app_state == 'disabled'
  end

  def app_enabled?
    !app_disabled?
  end

  def idea_disabled?
    idea_state == 'disabled'
  end

  def idea_enabled?
    !idea_disabled?
  end
end
