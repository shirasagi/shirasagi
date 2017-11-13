class Chorg::Changeset

  GROUP_ATTRIBUTES = %w(name order contact_tel contact_fax contact_email contact_link_url contact_link_name ldap_dn).freeze

  include Chorg::Model::Changeset
  include Cms::SitePermission

  set_permission_name 'chorg_revisions', :edit
  belongs_to :revision, class_name: 'Chorg::Revision'
end
