# coding: utf-8
module Facilitiy::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^facilitiy\//) }
  end

  class Page
    include Cms::Node::Model
    include Cms::Addon::PageList

    default_scope ->{ where(route: "facilitiy/page") }
  end

  class Category
    include Cms::Node::Model

    default_scope ->{ where(route: "facilitiy/category") }
  end
end
