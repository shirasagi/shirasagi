class Gws::Chorg::Revision
  include Chorg::Model::Revision
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name 'gws_chorg_revisions', :edit

  has_many :changesets, class_name: 'Gws::Chorg::Changeset', dependent: :destroy
  has_many :tasks, class_name: 'Gws::Chorg::Task', dependent: :destroy
end
