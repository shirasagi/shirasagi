module Gws::Addon::System::UserSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  USER_PUBLIC_PROFILES = %w(uid updated main_group user_title user_occupation email tel).freeze

  ORGANIZATION_UID_SORT_ORDERS = %w(alpha_first numeric_first).freeze

  included do
    field :user_public_profiles, type: SS::Extensions::Words
    field :organization_uid_sort_order, type: String, default: 'alpha_first'

    permit_params user_public_profiles: []
    permit_params :organization_uid_sort_order
  end

  def user_profile_public?(attr)
    user_public_profiles.blank? || user_public_profiles.include?(attr.to_s)
  end

  def organization_uid_sort_order_options
    ORGANIZATION_UID_SORT_ORDERS.map { |v| [I18n.t("gws.options.organization_uid_sort_order.#{v}"), v] }
  end

  def organization_uid_alpha_first?
    organization_uid_sort_order != 'numeric_first'
  end
end
