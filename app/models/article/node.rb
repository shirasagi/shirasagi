module Article::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^article\//) }
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
    include Category::Addon::Setting
    include Cms::Addon::TagSetting
    include Cms::Addon::ContentQuota
    include Cms::Addon::ForMemberNode
    include Cms::Addon::OpendataRef::Site
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
    include Cms::Addon::ImageResizeSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "article/page") }
  end

  class FormTable
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Article::Addon::FormTable
    include Cms::Addon::PageList
    include Cms::Addon::LayoutHtml
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "article/form_table") }
  end

  class MapSearch
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Article::Addon::MapSearch
    include Article::Addon::MapSearchResult
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "article/map_search") }
  end
end
