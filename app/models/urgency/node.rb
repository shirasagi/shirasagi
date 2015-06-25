module Urgency::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^urgency\//) }
  end

  class Layout
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Urgency::Addon::Layout
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "urgency/layout") }
  end
end
