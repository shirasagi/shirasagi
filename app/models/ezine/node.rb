module Ezine::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^ezine\//) }
  end

  class Page
    include Cms::Node::Model
    include Cms::Addon::PageList

    default_scope ->{ where(route: "ezine/page") }
  end
end
