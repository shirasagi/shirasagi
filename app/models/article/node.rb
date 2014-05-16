# coding: utf-8
module Article::Node
  class Base
    include Cms::Node::Model
    
    default_scope ->{ where(route: /^article\//) }
  end
  
  class Page
    include Cms::Node::Model
    include Cms::Addon::PageList
    
    default_scope ->{ where(route: "article/page") }
  end
end
