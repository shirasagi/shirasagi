module Facility::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^facility\//) }
  end

  class Node
    include Cms::Node::Model
    include Cms::Addon::NodeList
    include Facility::Addon::CategorySetting
    include Facility::Addon::ServiceSetting
    include Facility::Addon::LocationSetting

    default_scope ->{ where(route: "facility/node") }
  end

  class Page
    include Cms::Node::Model
    include Facility::Addon::Body
    include Facility::Addon::AdditionalInfo
    include Facility::Addon::Category
    include Facility::Addon::Service
    include Facility::Addon::Location

    default_scope ->{ where(route: "facility/page") }
  end

  class Search
    include Cms::Node::Model
    include Cms::Addon::NodeList
    include Facility::Addon::CategorySetting
    include Facility::Addon::ServiceSetting
    include Facility::Addon::LocationSetting

    default_scope ->{ where(route: "facility/search") }

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
    include Cms::Node::Model
    include Cms::Addon::NodeList
    include Facility::Addon::PointerImage

    default_scope ->{ where(route: "facility/category") }

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

  class Service
    include Cms::Node::Model
    include Cms::Addon::NodeList

    default_scope ->{ where(route: "facility/service") }

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
        cond << { :service_ids.in => cids } if cids.present?

        { '$or' => cond }
      end
  end

  class Location
    include Cms::Node::Model
    include Cms::Addon::NodeList

    default_scope ->{ where(route: "facility/location") }

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
        cond << { :location_ids.in => cids } if cids.present?

        { '$or' => cond }
      end
  end
end
