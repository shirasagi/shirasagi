module Faq::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^faq\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Event::Addon::PageList
    include Category::Addon::Setting
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "faq/page") }
  end

  class Search
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Event::Addon::PageList
    include Category::Addon::Setting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "faq/search") }

    def condition_hash
      conditions.present? ? super : {}
    end
  end
end
