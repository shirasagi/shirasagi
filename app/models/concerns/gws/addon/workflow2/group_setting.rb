module Gws::Addon::Workflow2::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :workflow_new_days, type: Integer
    field :workflow_my_group, type: String, default: "enabled"
    field :workflow_route_approver_superior, type: String, default: 'show'
    field :workflow_route_approver_title, type: String, default: 'show'
    field :workflow_route_approver_occupation, type: String, default: 'show'
    field :workflow_route_circulation_superior, type: String, default: 'show'
    field :workflow_route_circulation_title, type: String, default: 'show'
    field :workflow_route_circulation_occupation, type: String, default: 'show'
    permit_params :workflow_new_days, :workflow_my_group
    permit_params :workflow_route_approver_superior, :workflow_route_approver_title, :workflow_route_approver_occupation
    permit_params :workflow_route_circulation_superior, :workflow_route_circulation_title, :workflow_route_circulation_occupation
  end

  def workflow_my_group_options
    [
      [I18n.t("ss.options.state.enabled"), "enabled"],
      [I18n.t("ss.options.state.disabled"), "disabled"]
    ]
  end

  def workflow_new_days
    self[:workflow_new_days].presence || 7
  end

  def workflow_my_group_disabled?
    workflow_my_group == "disabled"
  end

  def workflow_route_approver_superior_options
    %w(show hide).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  alias workflow_route_approver_title_options workflow_route_approver_superior_options
  alias workflow_route_approver_occupation_options workflow_route_approver_superior_options
  alias workflow_route_circulation_superior_options workflow_route_approver_superior_options
  alias workflow_route_circulation_title_options workflow_route_approver_superior_options
  alias workflow_route_circulation_occupation_options workflow_route_approver_superior_options
end
