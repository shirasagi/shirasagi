class Cms::Node
  include Cms::Model::Node
  include SS::PluginRepository
  include Cms::Addon::NodeSetting
  include Cms::Addon::EditorSetting
  include Cms::Addon::GroupPermission
  include Cms::Addon::NodeTwitterPostSetting
  include Cms::Addon::NodeLinePostSetting
  include Cms::Addon::ForMemberNode
  include Cms::Lgwan::Node

  index({ site_id: 1, filename: 1 }, { unique: true })

  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^cms\//) }
  end

  class Node
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::EditorSetting
    include Cms::Addon::NodeTwitterPostSetting
    include Cms::Addon::NodeLinePostSetting
    include Cms::Addon::NodeList
    include Cms::Addon::ChildList
    include Cms::Addon::ContentQuota
    include Cms::Addon::ForMemberNode
    include Cms::Addon::Release
    include Cms::Addon::ReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "cms/node") }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::EditorSetting
    include Cms::Addon::NodeTwitterPostSetting
    include Cms::Addon::NodeLinePostSetting
    include Event::Addon::PageList
    include Cms::Addon::Form::Node
    include Cms::Addon::ContentQuota
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
    include Cms::Addon::ImageResizeSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::ChildList
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "cms/page") }

    self.use_condition_forms = true
  end

  class ImportNode
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Addon::Import::Page
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "cms/import_node") }
  end

  class Archive
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::ArchiveViewSwitcher
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "cms/archive") }

    self.use_no_archive_html = false
  end

  class GroupPage
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::PageGroupList
    include ::Cms::ChildList
    include History::Addon::Backup
    include Cms::Addon::Release
    include Cms::Lgwan::Node

    def child_items
      child_pages
    end

    def child_pages
      Cms::Page.site(site).and_public.
        where(self.condition_hash).
        order_by(self.sort_hash).
        limit(child_list_limit)
    end

    default_scope ->{ where(route: "cms/group_page") }
  end

  class PhotoAlbum
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    self.use_no_items_display = false
    self.use_substitute_html = false
    self.use_upper_html = false
    self.use_lower_html = false
    self.use_loop_html = false
    self.use_new_days = false
    self.use_liquid = false
    self.use_sort = false

    default_scope ->{ where(route: "cms/photo_album") }

    def condition_hash(options = {})
      super(options.reverse_merge(bind: :descendants, category: false, default_location: :only_blank))
    end
  end

  class SiteSearch
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Category::Addon::Setting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope -> { where(route: "cms/site_search") }

    def st_categories_sortable?
      true
    end
  end

  class LineHub
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "cms/line_hub") }
  end

  class FormSearch
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/form_search") }
  end
end
