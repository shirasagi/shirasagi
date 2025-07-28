# 多要素認証
module SS::MFA::SiteSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  MFA_USE_NONE = "none".freeze
  MFA_USE_ALWAYS = "always".freeze
  MFA_USE_UNTRUSTED = "untrusted".freeze
  MFA_USE_STATES = [ MFA_USE_NONE, MFA_USE_ALWAYS, MFA_USE_UNTRUSTED ].freeze

  included do
    field :mfa_otp_use_state, type: String
    field :mfa_trusted_ip_addresses, type: SS::Extensions::Lines

    permit_params :mfa_otp_use_state, :mfa_trusted_ip_addresses

    validates :mfa_otp_use_state, inclusion: { in: MFA_USE_STATES, allow_blank: true }
    validates :mfa_trusted_ip_addresses, ip_address: true
  end

  def mfa_otp_use_state_options
    MFA_USE_STATES.map do |v|
      [ I18n.t("ss.options.mfa_use.#{v}"), v ]
    end
  end

  def mfa_otp_use_none?
    mfa_otp_use_state.blank? || mfa_otp_use_state == MFA_USE_NONE
  end

  def mfa_otp_use?(request = nil)
    case mfa_otp_use_state
    when MFA_USE_ALWAYS
      true
    when MFA_USE_UNTRUSTED
      remote_addr = SS.remote_addr(request)
      trusted = mfa_trusted_ip_addresses.any? do |addr|
        next false if addr.blank? || addr.start_with?("#")

        addr = IPAddr.new(addr) rescue nil
        next false unless addr

        addr.include?(remote_addr)
      end
      !trusted
    end
  end
end
