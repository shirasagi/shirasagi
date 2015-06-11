module Urgency::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^urgency\//) }
  end

  class Layout
    include Cms::Model::Node
    include Urgency::Addon::Layout

    default_scope ->{ where(route: "urgency/layout") }
  end
end
