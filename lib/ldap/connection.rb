require 'net-ldap'

class Ldap::Connection
  private_class_method :new

  class << self
    def connect(host: SS.config.ldap.host, base_dn: nil, auth_method: SS.config.ldap.auth_method, username: nil, password: nil)
      return nil if host.blank?
      return nil if auth_method.blank?

      host, port = host.split(":", 2)
      config = { host: host }
      config[:port] = port.to_i if port.numeric?
      config[:base] = base_dn if base_dn.present?
      config[:auth] = { method: auth_method.to_sym, username: username, password: password }

      ldap = Net::LDAP.new(config)
      raise Ldap::BindError unless do_bind(ldap, auth_method, username, password)

      new(config)
    end

    def authenticate(host: SS.config.ldap.host, username: nil, password: nil)
      return false if host.blank?
      return false if username.blank?
      return false if password.blank?

      host, port = host.split(":", 2)
      config = { host: host }
      config[:port] = port.to_i if port.numeric?
      config[:base] = username

      ldap = Net::LDAP.new(config)
      do_bind(ldap, :simple, username, password) ? true : false
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
      ret = SS::Crypt.decrypt(password)
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
    search(Ldap::Group::DEFAULT_FILTER).map do |e|
      Ldap::Group.create(self, e)
    end.compact
  end

  def users
    search(Ldap::User::DEFAULT_FILTER).map do |e|
      Ldap::User.create(self, e)
    end.compact
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
