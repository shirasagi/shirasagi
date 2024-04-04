module SS::Ldap::SiteSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :ldap_use_state, type: String
    field :ldap_url, type: String
    field :ldap_openssl_verify_mode, type: String

    permit_params :ldap_use_state, :ldap_url, :ldap_openssl_verify_mode

    validates :ldap_use_state, inclusion: { in: %w(use_sys use_cms), allow_blank: true }
    validates :ldap_url, url: { scheme: %w(ldap ldaps) }
    validates :ldap_openssl_verify_mode, inclusion: { in: %w(none peer client_once fail_if_no_peer_cert), allow_blank: true }
  end

  def ldap_use_state_options
    %w(use_sys use_cms).map do |v|
      [ I18n.t("ldap.options.use_state.#{v}"), v ]
    end
  end

  def ldap_openssl_verify_mode_options
    %w(none peer).map do |v|
      [ v, v ]
    end
  end

  def ldap_use_state_sys?
    !ldap_use_state_cms?
  end

  def ldap_use_state_cms?
    ldap_use_state == "use_cms"
  end
end
