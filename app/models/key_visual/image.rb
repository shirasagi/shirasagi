class KeyVisual::Image
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include SS::Relation::File
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup
  include Cms::Lgwan::Page

  set_permission_name "key_visual_images"

  field :link_url, type: String
  field :remark, type: String

  belongs_to_file :file

  validates :file_id, presence: true
  validates :remark, length: { maximum: 400 }

  permit_params :link_url, :remark

  after_generate_file :generate_relation_public_file, if: ->{ public? }
  after_remove_file :remove_relation_public_file

  default_scope ->{ where(route: "key_visual/image") }
end
