module Gws::Addon::Survey::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :survey_default_due_date, type: Integer, default: 7
    field :survey_new_days, type: Integer

    permit_params :survey_default_due_date, :survey_new_days

    validates :survey_default_due_date, numericality: true
  end

  def survey_new_days
    self[:survey_new_days].presence || 7
  end
end
