module Garbage
  class Initializer
    Cms::Node.plugin "garbage/node"
    Cms::Node.plugin "garbage/page"
    Cms::Node.plugin "garbage/search"
    Cms::Node.plugin "garbage/category"
  end
end
