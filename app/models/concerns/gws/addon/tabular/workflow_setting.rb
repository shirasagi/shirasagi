module Gws::Addon::Tabular::WorkflowSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Workflow2::ApplicationSetting
  include Gws::Workflow2::DestinationSetting

  included do
    field :workflow_state, type: String, default: 'disabled'

    permit_params :workflow_state
    permit_params destination_group_ids: [], destination_user_ids: []

    validates :workflow_state, inclusion: { in: %w(disabled enabled), allow_blank: true }
  end

  def workflow_state_options
    %w(disabled enabled).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def workflow_enabled?
    workflow_state == "enabled"
  end
end
