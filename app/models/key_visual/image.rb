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

  belongs_to_file :file

  validates :in_file, presence: true, if: -> { file_id.blank? }

  permit_params :link_url

  default_scope ->{ where(route: "key_visual/image") }

  def serve_static_file?
    false
  end
end
