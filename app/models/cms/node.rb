class Cms::Node
  include Cms::Model::Node
  include Cms::PluginRepository
  include Cms::Addon::NodeSetting
  include Cms::Addon::GroupPermission

  index({ site_id: 1, filename: 1 }, { unique: true })

  class Base
    include Cms::Model::Node

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

    default_scope ->{ where(route: "cms/node") }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Event::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

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

    default_scope ->{ where(route: "cms/archive") }
  end

  class GroupPage
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::PageGroupList
    include History::Addon::Backup

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

    default_scope ->{ where(route: "cms/photo_album") }

    def condition_hash
      cond = []

      cond << { filename: /^#{filename}\// } if conditions.blank?
      conditions.each do |url|
        s = cur_site || site rescue nil
        node = Cms::Node.site(s).filename(url).first
        next unless node
        cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
      end

      { '$or' => cond }
    end
  end
end
