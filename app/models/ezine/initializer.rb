module Ezine
  class Initializer
    Cms::Node.plugin "ezine/page"
    Cms::Node.plugin "ezine/backnumber"
    Cms::Node.plugin "ezine/member_page"
    Cms::Node.plugin "ezine/category_node"
  end
end
