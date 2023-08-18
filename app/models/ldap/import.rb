class Ldap::Import
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  TYPE_GROUP = "group".freeze
  TYPE_USER = "user".freeze

  set_permission_name "cms_users", :edit

  seqid :id
  field :group_count, type: Integer
  field :user_count, type: Integer
  field :ldap, type: Ldap::Extensions::LdapArray
end
