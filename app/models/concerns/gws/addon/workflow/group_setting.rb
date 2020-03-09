module Gws::Addon::Workflow::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :workflow_new_days, type: Integer
    permit_params :workflow_new_days
  end

  def workflow_new_days
    self[:workflow_new_days].presence || 7
  end
end
