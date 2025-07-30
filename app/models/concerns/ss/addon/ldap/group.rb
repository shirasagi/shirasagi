module SS::Addon::Ldap::Group
  extend SS::Addon
  extend ActiveSupport::Concern
  include SS::Addon::Ldap::Common

  included do
    field :ldap_dn, type: String
    field :ldap_import_id, type: Integer
    permit_params :ldap_dn
    validates :ldap_dn, ldap_dn: true
    before_save :normalize_or_remove_ldap_dn
  end
end
