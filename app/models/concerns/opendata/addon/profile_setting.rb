module Opendata::Addon::ProfileSetting
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :edit_profile_state, type: String, default: "allow_all"

    permit_params :edit_profile_state
  end

  def edit_profile_state_options
    I18n.t("opendata.edit_profile_state_options").map { |k, v| [v, k] }
  end
end
