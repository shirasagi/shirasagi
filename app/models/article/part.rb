module Article::Part
  class Page
    include Cms::Model::Part
    include Cms::Addon::PageList

    default_scope ->{ where(route: "article/page") }
  end
end
