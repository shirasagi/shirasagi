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
    include Cms::Addon::NodeAutoPostSetting
    include Cms::Addon::NodeLinePostSetting
    include Event::Addon::PageList
    include Cms::Addon::Form::Node
    include Category::Addon::Setting
    include Cms::Addon::TagSetting
    include Cms::Addon::ForMemberNode
    include Cms::Addon::OpendataRef::Site
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "article/page") }
  end
end
