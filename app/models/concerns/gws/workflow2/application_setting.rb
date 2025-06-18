module Gws::Workflow2::ApplicationSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :approval_state, type: String, default: "with_approval"
    field :default_route_id, type: String, default: 'my_group'
    field :agent_state, type: String, default: 'disabled'

    permit_params :approval_state, :default_route_id, :agent_state

    validates :approval_state, presence: true, inclusion: { in: %w(without_approval with_approval), allow_blank: true }
    validates :agent_state, presence: true, inclusion: { in: %w(disabled enabled), allow_blank: true }
  end

  def approval_state_options
    %w(without_approval with_approval).map do |v|
      [ I18n.t("gws/workflow2.options.approval_state.#{v}"), v ]
    end
  end

  def agent_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("gws/workflow2.options.agent_state.#{v}"), v ]
    end
  end

  def approval_state_without_approval?
    approval_state == "without_approval"
  end

  def approval_state_with_approval?
    !approval_state_without_approval?
  end

  def route_my_group_alternate?
    default_route_id == "my_group_alternate"
  end

  def agent_enabled?
    agent_state == 'enabled'
  end
end
