module Article::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^article\//) }
  end

  class Page
    include Cms::Node::Model
    include Cms::Addon::PageList
    include Category::Addon::Setting

    default_scope ->{ where(route: "article/page") }
  end
end
