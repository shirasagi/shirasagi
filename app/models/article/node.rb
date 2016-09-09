module Article::Node
  class Base
    include Cms::Model::Node
    include Multilingual::Addon::Node

    default_scope ->{ where(route: /^article\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Category::Addon::Setting
    include Cms::Addon::OpendataSite
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Multilingual::Addon::Node

    default_scope ->{ where(route: "article/page") }
  end
end
