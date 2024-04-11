# 多要素認証
module SS::Addon::MFA::UserSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :mfa_otp_secret, type: String
    field :mfa_otp_enabled_at, type: DateTime
  end
end
