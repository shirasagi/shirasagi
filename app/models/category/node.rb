module Category::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^category\//) }
  end

  class Node
    include Cms::Model::Node
    include Cms::Addon::NodeList

    default_scope ->{ where(route: "category/node") }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::PageList

    default_scope ->{ where(route: "category/page") }
  end
end
