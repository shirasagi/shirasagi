class Gws::Chorg::Changeset

  GROUP_ATTRIBUTES = %w(name order ldap_dn).freeze

  include Chorg::Model::Changeset
  include Gws::SitePermission

  set_permission_name 'gws_chorg_revisions', :edit
  belongs_to :revision, class_name: 'Gws::Chorg::Revision'
end
