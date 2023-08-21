module Gws::Addon::Report::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :report_new_days, type: Integer
    permit_params :report_new_days
  end

  def report_new_days
    self[:report_new_days].presence || 7
  end
end
