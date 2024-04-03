module SS::Ldap::SiteSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :ldap_url, type: String
    field :ldap_openssl_verify_mode, type: String

    permit_params :ldap_url, :ldap_openssl_verify_mode

    validates :ldap_url, url: { scheme: %w(ldap ldaps) }
    validates :ldap_openssl_verify_mode, inclusion: { in: %w(none peer client_once fail_if_no_peer_cert), allow_blank: true }
  end

  def ldap_openssl_verify_mode_options
    %w(none peer).map do |v|
      [ v, v ]
    end
  end
end
