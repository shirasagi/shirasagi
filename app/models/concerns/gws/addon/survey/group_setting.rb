module Gws::Addon::Survey::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :survey_default_due_date, type: Integer, default: 7

    permit_params :survey_default_due_date

    validates :survey_default_due_date, numericality: true
  end
end

