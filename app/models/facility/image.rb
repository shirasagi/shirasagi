class Facility::Image
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Facility::Addon::ImageFile
  include Facility::Addon::ImageInfo
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include Cms::Lgwan::Page

  default_scope ->{ where(route: "facility/image") }

  after_save :save_facility

  private

  def save_facility
    parent.save rescue nil
  end

  def serve_static_file?
    false
  end
end
