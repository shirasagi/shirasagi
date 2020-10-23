module Garbage::Node
  class Base
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::GroupPermission

    default_scope ->{ where(route: /^garbage\//) }
  end

  class Node
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Garbage::Addon::CategorySetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "garbage/node") }

    def sort_hash
      return { name: 1 } if sort.blank?
      super
    end
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Garbage::Addon::Body
    include Garbage::Addon::Category
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "garbage/page") }
  end

  class Search
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Garbage::Addon::CategorySetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "garbage/search") }

    def condition_hash(options = {})
      super(options.reverse_merge(bind: :descendants, category: false, default_location: :only_blank, request_dir: false))
    end

    def sort_hash
      return { name: 1 } if sort.blank?
      super
    end
  end

  class Category
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "garbage/category") }

    def condition_hash(options = {})
      super(options.reverse_merge(request_dir: false, wildcard: false))
    end

    def sort_hash
      return { name: 1 } if sort.blank?
      super
    end
  end
end
