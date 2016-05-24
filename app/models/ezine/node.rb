module Ezine::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^ezine\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Ezine::Addon::Signature
    include Ezine::Addon::SenderAddress
    include Ezine::Addon::Reply
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    has_many :columns, class_name: "Ezine::Column"

    default_scope ->{ where(route: "ezine/page") }
  end

  class Backnumber
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "ezine/backnumber") }

    def condition_hash
      h = super
      h['$or'] << { filename: /^#{parent.filename}\//, depth: self.depth }
      h
    end
  end
end
