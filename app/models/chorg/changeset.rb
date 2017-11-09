class Chorg::Changeset
  include Chorg::Model::Changeset
  include Cms::SitePermission

  set_permission_name 'chorg_revisions', :edit
  belongs_to :revision, class_name: 'Chorg::Revision'
end
