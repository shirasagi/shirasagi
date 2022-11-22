module Gws::Addon::DailyReport::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :daily_report_new_days, type: Integer
    permit_params :daily_report_new_days
  end

  def daily_report_new_days
    self[:daily_report_new_days].presence || 7
  end
end
