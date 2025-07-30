require 'net-ldap'

class Ldap::Connection
  private_class_method :new

  class << self
    # rubocop:disable Metrics/ParameterLists
    def connect(url:, openssl_verify_mode: nil, base_dn: nil, auth_method: :anonymous, username: nil, password: nil)
      return nil if url.blank?
      return nil if auth_method.blank?

      url = Addressable::URI.parse(url)
      host = url.host
      port = url.port || (url.scheme == 'ldaps' ? URI::LDAPS::DEFAULT_PORT : URI::LDAP::DEFAULT_PORT)

      config = { host: host, port: port }
      if url.scheme == 'ldaps'
        config[:encryption] = { method: :simple_tls }
        if openssl_verify_mode == "none"
          # 証明書の検証を無効化
          config[:encryption][:tls_options] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
        end
      end
      config[:base] = base_dn if base_dn.present?
      config[:auth] = { method: auth_method.to_sym, username: username, password: password }

      ldap = Net::LDAP.new(config)
      raise Ldap::BindError unless do_bind(ldap, auth_method, username, password)

      new(config)
    end
    # rubocop:enable Metrics/ParameterLists

    def authenticate(url:, openssl_verify_mode: nil, username: nil, password: nil)
      return false if url.blank?
      return false if username.blank?
      return false if password.blank?

      url = Addressable::URI.parse(url)
      host = url.host
      port = url.port || (url.scheme == 'ldaps' ? URI::LDAPS::DEFAULT_PORT : URI::LDAP::DEFAULT_PORT)

      config = { host: host, port: port }
      if url.scheme == 'ldaps'
        config[:encryption] = { method: :simple_tls }
        if openssl_verify_mode == "none"
          # 証明書の検証を無効化
          config[:encryption][:tls_options] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
        end
      end

      ldap = Net::LDAP.new(config)
      do_bind(ldap, :simple, username, password) ? true : false
    end

    def change_password(username: nil, new_password: nil)
      return false if username.blank?
      return false if new_password.blank?

      url = ::Ldap.url
      openssl_verify_mode = ::Ldap.openssl_verify_mode
      auth_method = ::Ldap.auth_method
      admin_user = ::Ldap.admin_user
      admin_pass = ::Ldap.admin_password

      url = Addressable::URI.parse(url)
      host = url.host
      port = url.port || (url.scheme == 'ldaps' ? URI::LDAPS::DEFAULT_PORT : URI::LDAP::DEFAULT_PORT)

      config = { host: host, port: port }
      if url.scheme == 'ldaps'
        config[:encryption] = { method: :simple_tls }
        if openssl_verify_mode == "none"
          # 証明書の検証を無効化
          config[:encryption][:tls_options] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
        end
      end
      config[:auth] = { method: auth_method.to_sym, username: admin_user, password: admin_pass }

      ldap = Net::LDAP.new(config)
      unless do_bind(ldap, auth_method, admin_user, admin_pass)
        return false
      end

      opts = [[ :replace, :userPassword, new_password ]]
      ldap.modify(dn: username, operations: opts)
    end

    def split_dn(ldap_dn)
      index = ldap_dn.index(",")
      return nil if index.nil?

      first = ldap_dn[0..index - 1].strip
      remains = ldap_dn[index + 1..-1].strip

      key, value = first.split("=", 2)
      filter = Net::LDAP::Filter.eq(key.strip, value.strip)

      [ filter, remains ]
    end

    def decrypt(password)
      ret = SS::Crypto.decrypt(password)
      ret.present? ? ret : password
    end

    private

    def do_bind(ldap, auth_method, username, password)
      auth_method = auth_method.to_sym
      auth = { method: auth_method.to_sym }
      if auth_method != :anonymous
        auth[:username] = username
        auth[:password] = decrypt(password)
      end
      ldap.bind(auth)
    end
  end

  attr_reader :config

  def initialize(config)
    @config = config
  end

  def search(filter, base: nil, scope: Net::LDAP::SearchScope_SingleLevel)
    params = { filter: filter }
    params[:base] = base if base.present?
    params[:scope] = scope if scope.present?

    copy = self.config.dup
    copy[:auth][:password] = self.class.decrypt(copy[:auth][:password])
    Net::LDAP.open(copy) do |ldap|
      ldap.search(params) || []
    end
  end

  def groups
    search(Ldap::Group::DEFAULT_FILTER).filter_map do |e|
      Ldap::Group.create(self, e)
    end
  end

  def users
    search(Ldap::User::DEFAULT_FILTER).filter_map do |e|
      Ldap::User.create(self, e)
    end
  end

  def find(ldap_dn, klass)
    filter, base = Ldap::Connection.split_dn(ldap_dn)
    filter = Net::LDAP::Filter.join(klass::DEFAULT_FILTER, filter)
    entries = search(filter, base: base)
    return nil if entries.nil?

    entries = entries.map do |e|
      klass.create(self, e)
    end
    entries.first
  end
end
