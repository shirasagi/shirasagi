# coding: utf-8
module Category
  class Initializer
    Cms::Page.addon "category/category"
    Article::Node::Page.addon "category/setting"
    Faq::Node::Page.addon "category/setting"
    Faq::Node::Search.addon "category/setting"

    Cms::Node.plugin "category/node"
    Cms::Node.plugin "category/page"
    Cms::Part.plugin "category/node"
  end
end
