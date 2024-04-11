module Cms::Ldap::ImportSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :ldap_base_dn, type: String
    field :ldap_auth_method, type: String
    field :ldap_user_dn, type: String
    field :ldap_user_password, type: String
    field :ldap_exclude_groups, type: SS::Extensions::Words, default: ->{ %w(Group People) }

    attr_accessor :in_ldap_user_password

    before_validation :set_ldap_user_password

    validates :ldap_base_dn, ldap_dn: true
    validates :ldap_auth_method, inclusion: { in: %w(simple anonymous), allow_blank: true }
    validates :ldap_user_dn, ldap_dn: true
  end

  def ldap_auth_method_options
    %w(simple anonymous).map { |v| [ I18n.t("ldap.options.auth_method.#{v}"), v ] }
  end

  private

  def set_ldap_user_password
    if in_ldap_user_password
      self.ldap_user_password = SS::Crypto.encrypt(in_ldap_user_password)
    end
  end
end
