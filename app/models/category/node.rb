module Category::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^category\//) }
  end

  class Node
    include Cms::Node::Model
    include Cms::Addon::NodeList

    default_scope ->{ where(route: "category/node") }
  end

  class Page
    include Cms::Node::Model
    include Cms::Addon::PageList

    default_scope ->{ where(route: "category/page") }
  end
end
