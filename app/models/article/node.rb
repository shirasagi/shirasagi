module Article::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^article\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::PageList
    include Category::Addon::Setting

    default_scope ->{ where(route: "article/page") }
  end
end
