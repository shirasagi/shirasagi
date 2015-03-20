module Ldap::Addon
  module Common
    def validate_ldap_dn
      if ldap_dn.present?
        require 'net/ldap/dn'
        Net::LDAP::DN.new(ldap_dn).to_a
      end
    rescue
      errors.add :ldap_dn, :invalid
    end

    def normalize_or_remove_ldap_dn
      if ldap_dn.blank?
        remove_attribute(:ldap_dn)
      else
        require 'net/ldap/dn'
        normalized_dn = []
        Net::LDAP::DN.new(ldap_dn).each_pair { |k, v| normalized_dn << "#{k}=#{v}" }
        self.ldap_dn = normalized_dn.join(",")
      end
    end
  end

  module Group
    extend SS::Addon
    extend ActiveSupport::Concern
    include Common

    set_order 320

    LDAP_AUTH_METHOD_PASSWORD = "password".freeze
    LDAP_AUTH_METHOD_ANONYMOUS = "anonymous".freeze
    LDAP_AUTH_METHODS = [ LDAP_AUTH_METHOD_PASSWORD, LDAP_AUTH_METHOD_ANONYMOUS ].freeze

    included do
      field :ldap_host, type: String
      field :ldap_dn, type: String
      field :ldap_auth_method, type: String, default: LDAP_AUTH_METHOD_PASSWORD
      field :ldap_import_id, type: Integer
      permit_params :ldap_host, :ldap_dn, :ldap_auth_method
      validate :validate_ldap_dn
      before_save :normalize_or_remove_ldap_dn
    end

    public
      def ldap_auth_method_option
        found = self.class.ldap_auth_method_options.select do |_, value|
          value == ldap_auth_method
        end.first
        return found[0] if found.present?
        self.class.ldap_auth_method_options.first[0]
      end

      def ldap_anonymous?
        LDAP_AUTH_METHOD_ANONYMOUS == ldap_auth_method
      end

    module ClassMethods
      def ldap_auth_method_options
        prefix = "modules.attributes.ldap/group.auth_method_options"
        LDAP_AUTH_METHODS.map { |e| [ I18n.t("#{prefix}.#{e}"), e ] }.to_a
      end
    end
  end

  module User
    extend SS::Addon
    extend ActiveSupport::Concern
    include Common

    set_order 320

    included do
      field :ldap_dn, type: String
      field :ldap_import_id, type: Integer
      permit_params :ldap_dn
      validate :validate_ldap_dn
      before_save :normalize_or_remove_ldap_dn
    end

    public
      def ldap_authenticate(password)
        return false unless cur_group
        return false unless login_roles.include?(SS::User::Model::LOGIN_ROLE_LDAP)
        return false if ldap_dn.blank?
        Ldap::Connection.authenticate(username: ldap_dn, password: password)
      rescue => e
        Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        false
      end
  end
end
