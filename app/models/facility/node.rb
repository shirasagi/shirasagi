module Facility::Node
  class Base
    include Cms::Model::Node
    include Cms::Addon::NodeSetting

    default_scope ->{ where(route: /^facility\//) }
  end

  class Node
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Facility::Addon::CategorySetting
    include Facility::Addon::ServiceSetting
    include Facility::Addon::LocationSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/node") }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Facility::Addon::Body
    include Cms::Addon::AdditionalInfo
    include Facility::Addon::Category
    include Facility::Addon::Service
    include Facility::Addon::Location
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/page") }

    def serve_static_file?
      false
    end
  end

  class Search
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Facility::Addon::CategorySetting
    include Facility::Addon::ServiceSetting
    include Facility::Addon::LocationSetting
    include Facility::Addon::SearchSetting
    include Facility::Addon::SearchResult
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/search") }

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
    include Facility::Addon::IconSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/category") }

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
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/service") }

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
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Facility::Addon::FocusSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/location") }

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
