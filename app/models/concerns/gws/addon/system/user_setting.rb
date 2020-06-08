module Gws::Addon::System::UserSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  USER_PUBLIC_PROFILES = %w(uid updated main_group user_title email tel).freeze

  included do
    field :user_public_profiles, type: SS::Extensions::Words

    permit_params user_public_profiles: []
  end

  def user_profile_public?(attr)
    user_public_profiles.blank? || user_public_profiles.include?(attr.to_s)
  end
end
