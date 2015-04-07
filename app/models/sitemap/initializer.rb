module Sitemap
  class Initializer
    Cms::Node.plugin "sitemap/page"

    Cms::Role.permission :read_other_sitemap_pages
    Cms::Role.permission :read_private_sitemap_pages
    Cms::Role.permission :edit_other_sitemap_pages
    Cms::Role.permission :edit_private_sitemap_pages
    Cms::Role.permission :delete_other_sitemap_pages
    Cms::Role.permission :delete_private_sitemap_pages
    Cms::Role.permission :move_private_sitemap_pages
    Cms::Role.permission :move_other_sitemap_pages
    Cms::Role.permission :release_other_sitemap_pages
    Cms::Role.permission :release_private_sitemap_pages
    Cms::Role.permission :approve_other_sitemap_pages
    Cms::Role.permission :approve_private_sitemap_pages
  end
end
