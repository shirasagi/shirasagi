class Cms::Node
  include Cms::Model::Node
  include Cms::PluginRepository
  include Cms::Addon::NodeSetting
  include Cms::Addon::GroupPermission
  include Multilingual::Addon::Node

  index({ site_id: 1, filename: 1 }, { unique: true })

  class Base
    include Cms::Model::Node
    include Multilingual::Addon::Node

    default_scope ->{ where(route: /^cms\//) }
  end

  class Node
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Multilingual::Addon::Node

    default_scope ->{ where(route: "cms/node") }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Multilingual::Addon::Node

    default_scope ->{ where(route: "cms/page") }
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
    include Multilingual::Addon::Node

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
    include Multilingual::Addon::Node

    default_scope ->{ where(route: "cms/archive") }
  end
end
