class Ldap::Import
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::Permission

  TYPE_GROUP = "group"
  TYPE_USER = "user"

  set_permission_name "cms_users", :edit

  seqid :id
  field :group_count, type: Integer
  field :user_count, type: Integer
  field :ldap, type: Ldap::Extensions::LdapArray
  field :results, type: Hash
end
