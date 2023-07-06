module Gws::Addon::Survey::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :survey_default_due_date, type: Integer, default: 7
    field :survey_answered_state, type: String, default: "both"
    field :survey_sort, type: String, default: "due_date_asc"
    field :survey_new_days, type: Integer

    permit_params :survey_default_due_date, :survey_answered_state,
      :survey_sort, :survey_new_days

    validates :survey_default_due_date, numericality: true
  end

  def survey_new_days
    self[:survey_new_days].presence || 7
  end

  def survey_answered_state_options
    Gws::Survey::Form.answered_state_options
  end

  def survey_sort_options
    Gws::Survey::Form.sort_options
  end
end
