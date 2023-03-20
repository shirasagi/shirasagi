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
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "urgency/layout") }

    before_validation :set_default_state

    private

    def set_default_state
      self.state = "closed"
    end
  end
end
