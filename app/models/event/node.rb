module Event::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^event\//) }
  end

  class Page
    include Cms::Node::Model
    include Event::Addon::PageList

    default_scope ->{ where(route: "event/page") }
  end
end
