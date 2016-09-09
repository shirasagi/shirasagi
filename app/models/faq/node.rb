module Faq::Node
  class Base
    include Cms::Model::Node
    include Multilingual::Addon::Node

    default_scope ->{ where(route: /^faq\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Category::Addon::Setting
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Multilingual::Addon::Node

    default_scope ->{ where(route: "faq/page") }
  end

  class Search
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Category::Addon::Setting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Multilingual::Addon::Node

    default_scope ->{ where(route: "faq/search") }

    def condition_hash
      conditions.present? ? super : {}
    end
  end
end
