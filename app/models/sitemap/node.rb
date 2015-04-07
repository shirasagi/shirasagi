module Sitemap::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^sitemap\//) }
  end

  class Page
    include Cms::Node::Model

    default_scope ->{ where(route: "sitemap/page") }
  end
end
