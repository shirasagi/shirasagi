require 'net-ldap'

class Ldap::Connection
  DEFAULT_PORT = 389.freeze

  private_class_method :new

  class << self
    public
      def connect(root_group, username, password)
        return nil if root_group.ldap_host.blank?
        return nil if root_group.ldap_dn.blank?

        if root_group.ldap_anonymous?
          config = create_anonymous_config(root_group)
        else
          config = create_auth_config(root_group, username, password)
        end
        return nil if config.blank?

        host, port = config[:host].split(":")
        port = port.present? ? port.to_i : DEFAULT_PORT
        ldap = Net::LDAP.new(host: host, port: port, base: config[:base_dn])
        raise Ldap::BindError unless do_bind(ldap, config)
        new(ldap, config)
      end

      def authenticate(root_group, username, password)
        return false if root_group.ldap_host.blank?
        return false if root_group.ldap_dn.blank?

        config = create_auth_config(root_group, username, password)
        return false if config.blank?

        host, port = config[:host].split(":")
        port = port.present? ? port.to_i : DEFAULT_PORT
        ldap = Net::LDAP.new(host: host, port: port, base: config[:base_dn])
        return false unless do_bind(ldap, config)
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
      def create_anonymous_config(root_group)
        config = {}
        config[:host] = root_group.ldap_host
        config[:base_dn] = root_group.ldap_dn
        config[:auth_method] = :anonymous
        config
      end

      def create_auth_config(root_group, username, password)
        return nil if username.blank?
        return nil if password.blank?

        config = {}
        config[:host] = root_group.ldap_host
        config[:base_dn] = root_group.ldap_dn
        config[:auth_method] = :simple
        config[:username] = username
        config[:password] = password
        config
      end

      def do_bind(ldap, config)
        method = config[:auth_method].to_sym
        auth = { method: method }
        if method != :anonymous
          auth[:username] = config[:username]
          auth[:password] = decrypt(config[:password])
        end
        ldap.bind(auth)
      end

      def decrypt(password)
        ret = SS::Crypt.decrypt(password)
        ret.present? ? ret : password
      end
  end

  public
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
      @ldap.search(params)
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
