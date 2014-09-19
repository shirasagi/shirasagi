# coding: utf-8
module Map
  class Initializer
    Cms::Node.plugin "map/page"

    Cms::Role.permission :read_other_map_pages
    Cms::Role.permission :read_private_map_pages
    Cms::Role.permission :edit_other_map_pages
    Cms::Role.permission :edit_private_map_pages
    Cms::Role.permission :delete_other_map_pages
    Cms::Role.permission :delete_private_map_pages
  end
end
