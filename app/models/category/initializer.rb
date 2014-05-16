# coding: utf-8
module Category
  class Initializer
    Cms::Page.addon "category/category"
    
    Cms::Node.plugin "category/node"
    Cms::Node.plugin "category/page"
    Cms::Part.plugin "category/node"
  end
end
