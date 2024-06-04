module Gws::Addon::Workflow::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :workflow_new_days, type: Integer
    field :workflow_my_group, type: String, default: ->{ SS.config.workflow.disable_my_group ? "disabled" : "enabled" }
    permit_params :workflow_new_days, :workflow_my_group
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
end
