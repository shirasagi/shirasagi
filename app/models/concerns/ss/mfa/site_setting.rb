# 多要素認証
module SS::MFA::SiteSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :mfa_use_state, type: String
    field :mfa_trusted_ip_addresses, type: SS::Extensions::Lines

    permit_params :mfa_use_state, :mfa_trusted_ip_addresses

    validates :mfa_use_state, inclusion: { in: %w(always untrusted allow none), allow_blank: true }
    validates :mfa_trusted_ip_addresses, ip_address: true
  end

  def mfa_use_state_options
    %w(always untrusted none).map do |v|
      [ I18n.t("ss.options.mfa_use.#{v}"), v ]
    end
  end
end
