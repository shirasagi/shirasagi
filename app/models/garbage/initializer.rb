module Garbage
  class Initializer
    Cms::Node.plugin "garbage/node"
    Cms::Node.plugin "garbage/page"
    Cms::Node.plugin "garbage/search"
    Cms::Node.plugin "garbage/category_list"
    Cms::Node.plugin "garbage/category"
    Cms::Node.plugin "garbage/area_list"
    Cms::Node.plugin "garbage/area"
    Cms::Node.plugin "garbage/center_list"
    Cms::Node.plugin "garbage/center"
    Cms::Node.plugin "garbage/remark_list"
    Cms::Node.plugin "garbage/remark"
  end
end
