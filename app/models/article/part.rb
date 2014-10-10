module Article::Part
  class Page
    include Cms::Part::Model
    include Cms::Addon::PageList

    default_scope ->{ where(route: "article/page") }
  end
end
