module Sitemap::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^sitemap\//) }
  end

  class Page
    include Cms::Model::Node

    default_scope ->{ where(route: "sitemap/page") }
  end
end
