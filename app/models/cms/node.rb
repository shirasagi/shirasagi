class Cms::Node
  include Cms::Model::Node
  include Cms::PluginRepository
  include Cms::Addon::NodeSetting
  include Cms::Addon::EditorSetting
  include Cms::Addon::GroupPermission
  include Cms::Addon::NodeAutoPostSetting
  include Cms::Addon::ForMemberNode

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
    include Cms::Addon::NodeAutoPostSetting
    include Cms::Addon::NodeList
    include Cms::Addon::ChildList
    include Cms::Addon::ForMemberNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/node") }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::EditorSetting
    include Cms::Addon::NodeAutoPostSetting
    include Event::Addon::PageList
    include Cms::Addon::Form::Node
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::ChildList

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
    include ::Cms::ChildList
    include History::Addon::Backup

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

    default_scope ->{ where(route: "cms/photo_album") }

    def condition_hash
      cond = []

      cond << { filename: /^#{::Regexp.escape(filename)}\// } if conditions.blank?
      conditions.each do |url|
        node = Cms::Node.site(cur_site || site).filename(url).first rescue nil
        next unless node
        cond << { filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1 }
      end

      { '$or' => cond }
    end
  end

  class SiteSearch
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/site_search") }
  end
end
