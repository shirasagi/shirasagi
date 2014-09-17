# coding: utf-8
module Facility::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^facility\//) }
  end

  class Page
    include Cms::Node::Model
    include Cms::Addon::PageList

    default_scope ->{ where(route: "facility/page") }
  end

  class Search
    include Cms::Node::Model
    include Facility::Addon::Location::Setting
    include Facility::Addon::Use::Setting
    include Facility::Addon::Type::Setting

    default_scope ->{ where(route: "facility/search") }
  end

  class Category
    include Cms::Node::Model

    default_scope ->{ where(route: "facility/category") }
  end
end
