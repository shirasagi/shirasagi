module Article::Part
  class Page
    include Cms::Model::Part
    include Event::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "article/page") }
  end
end
