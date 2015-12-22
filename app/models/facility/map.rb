class Facility::Map
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Map::Addon::Page
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission

  default_scope ->{ where(route: "facility/map") }

  private
    def serve_static_file?
      false
    end
end
