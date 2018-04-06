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
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Garbage::Addon::Body
    #include Garbage::Addon::AdditionalInfo
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

    public
      def condition_hash
        cond = []

        cond << { filename: /^#{filename}\// } if conditions.blank?
        conditions.each do |url|
          node = Cms::Node.filename(url).first
          next unless node
          cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
        end

        { '$or' => cond }
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

    public
      def condition_hash
        cond = []
        cids = []

        cids << id
        conditions.each do |url|
          node = Cms::Node.filename(url).first
          next unless node
          cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
          cids << node.id
        end
        cond << { :category_ids.in => cids } if cids.present?

        { '$or' => cond }
      end
  end
end
