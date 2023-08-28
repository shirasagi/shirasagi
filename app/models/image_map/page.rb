class ImageMap::Page
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Cms::Addon::EditLock
  include Workflow::Addon::Branch
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include ImageMap::Addon::Area
  include Cms::Addon::Body
  include Cms::Addon::BodyPart
  include Cms::Addon::File
  include Cms::Addon::Form::Page
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  after_save :new_size_input, if: ->{ changes.present? || previous_changes.present? }

  set_permission_name "image_map_pages"

  default_scope ->{ where(route: "image_map/page") }

  def serve_static_file?
    false
  end
end
