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

    included do
      field :ldap_dn, type: String
      field :ldap_import_id, type: Integer
      permit_params :ldap_dn
      validate :validate_ldap_dn
      before_save :normalize_or_remove_ldap_dn
    end
  end

  module User
    extend SS::Addon
    extend ActiveSupport::Concern
    include Common

    included do
      field :ldap_dn, type: String
      field :ldap_import_id, type: Integer
      permit_params :ldap_dn
      validate :validate_ldap_dn
      before_save :normalize_or_remove_ldap_dn
    end

    public
      def ldap_authenticate(password)
        return false unless login_roles.include?(SS::User::LOGIN_ROLE_LDAP)
        return false if ldap_dn.blank?
        Ldap::Connection.authenticate(username: ldap_dn, password: password)
      rescue => e
        Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        false
      end
  end
end
