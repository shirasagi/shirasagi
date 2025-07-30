module SS::Ldap::SiteSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :ldap_use_state, type: String
    field :ldap_url, type: String
    field :ldap_openssl_verify_mode, type: String

    permit_params :ldap_use_state, :ldap_url, :ldap_openssl_verify_mode

    validates :ldap_use_state, inclusion: { in: %w(system individual), allow_blank: true }
    validates :ldap_url, url: { scheme: %w(ldap ldaps) }
    validates :ldap_openssl_verify_mode, inclusion: { in: %w(none peer client_once fail_if_no_peer_cert), allow_blank: true }
  end

  def ldap_use_state_options
    %w(system individual).map do |v|
      [ I18n.t("ldap.options.use_state.#{v}"), v ]
    end
  end

  def ldap_openssl_verify_mode_options
    %w(none peer).map do |v|
      [ v, v ]
    end
  end

  def ldap_use_state_system?
    !ldap_use_state_individual?
  end

  def ldap_use_state_individual?
    ldap_use_state == "individual"
  end

  def ldap_config
    url = Addressable::URI.parse(ldap_url)
    host = url.host
    port = url.port || (url.scheme == 'ldaps' ? URI::LDAPS::DEFAULT_PORT : URI::LDAP::DEFAULT_PORT)

    config = { host: host, port: port }
    if url.scheme == 'ldaps'
      config[:encryption] = { method: :simple_tls }
      if ldap_openssl_verify_mode == "none"
        # 証明書の検証を無効化
        config[:encryption][:tls_options] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
      end
    end
    config
  end
end
