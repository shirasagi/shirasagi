class Chorg::Revision
  include Chorg::Model::Revision
  include SS::Reference::Site
  include Chorg::Addon::Option
  include Cms::SitePermission

  set_permission_name 'chorg_revisions', :edit

  has_many :changesets, class_name: 'Chorg::Changeset', dependent: :destroy
  has_many :tasks, class_name: 'Chorg::Task', dependent: :destroy
  belongs_to_file :content_csv_file
end
