require 'net-ldap'

class Ldap::Connection
  private_class_method :new

  class << self
    def connect(host: SS.config.ldap.host, base_dn: nil, auth_method: SS.config.ldap.auth_method, username: nil, password: nil)
      return nil if host.blank?
      return nil if auth_method.blank?

      host, port = host.split(":")
      config = { host: host }
      config[:port] = port.to_i if port.present?
      config[:base] = base_dn if base_dn.present?
      config[:auth_method] = auth_method.to_sym

      ldap = Net::LDAP.new(config)
      raise Ldap::BindError unless do_bind(ldap, auth_method, username, password)
      new(ldap, config)
    end

    def authenticate(host: SS.config.ldap.host, username: nil, password: nil)
      return false if host.blank?
      return false if username.blank?
      return false if password.blank?

      host, port = host.split(":")
      config = { host: host }
      config[:port] = port.to_i if port.present?
      config[:base] = username

      ldap = Net::LDAP.new(config)
      return false unless do_bind(ldap, :simple, username, password)
      true
    end

    def split_dn(dn)
      index = dn.index(",")
      return nil if index.nil?

      first = dn[0..index - 1].strip
      remains = dn[index + 1..-1].strip

      key, value = first.split("=")
      filter = Net::LDAP::Filter.eq(key.strip, value.strip)

      [ filter, remains ]
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

      def decrypt(password)
        ret = SS::Crypt.decrypt(password)
        ret.present? ? ret : password
      end
  end

  def initialize(ldap, config)
    @ldap = ldap
    @config = config
  end

  def config
    @config
  end

  def search(filter, base: nil, scope: Net::LDAP::SearchScope_SingleLevel)
    params = { filter: filter }
    params[:base] = base if base.present?
    params[:scope] = scope if scope.present?
    @ldap.search(params) || []
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

  def find(dn, klass)
    filter, base = Ldap::Connection.split_dn(dn)
    filter = Net::LDAP::Filter.join(klass::DEFAULT_FILTER, filter)
    entries = search(filter, base: base)
    return nil if entries.nil?
    entries = entries.map do |e|
      klass.create(self, e)
    end
    entries.first
  end
end
