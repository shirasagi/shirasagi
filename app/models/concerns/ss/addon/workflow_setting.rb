module SS::Addon::WorkflowSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :workflow_my_group, type: String, default: "enabled"
    field :workflow_default_comment, type: String
    permit_params :workflow_my_group, :workflow_default_comment
  end

  def workflow_my_group_options
    [
      [I18n.t("ss.options.state.enabled"), "enabled"],
      [I18n.t("ss.options.state.disabled"), "disabled"]
    ]
  end

  def workflow_my_group_disabled?
    workflow_my_group == "disabled"
  end
end
