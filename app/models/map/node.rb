# coding: utf-8
module Map::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^map\//) }
  end

  class Page
    include Cms::Node::Model
    include Cms::Addon::PageList

    default_scope ->{ where(route: "map/page") }
  end
end
