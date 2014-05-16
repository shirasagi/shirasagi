# coding: utf-8
module Article
  class Initializer
    Cms::Node.plugin "article/page"
    Cms::Part.plugin "article/page"
  end
  
  Cms::Page.instance_exec do
    def addon(*args)
      Article::Page.addon(*args) and super
    end
  end
  Article::Page.inherit_addons Cms::Page
  
end
