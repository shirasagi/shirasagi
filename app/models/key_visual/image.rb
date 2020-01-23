class KeyVisual::Image
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include SS::Relation::File
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "key_visual_images"

  field :link_url, type: String

  belongs_to_file2 :file

  validates :file_id, presence: true

  permit_params :link_url

  after_generate_file :generate_relation_public_file, if: ->{ public? }
  after_remove_file :remove_relation_public_file

  default_scope ->{ where(route: "key_visual/image") }
end
