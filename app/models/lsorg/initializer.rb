module Lsorg
  class Initializer
    Cms::Node.plugin "lsorg/node"
    Cms::Node.plugin "lsorg/page"

    Cms::Role.permission :import_lsorg_node_pages
  end
end
