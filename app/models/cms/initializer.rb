# coding: utf-8
module Cms
  class Initializer
    Cms::Page.addon "cms/meta"
    Cms::Page.addon "cms/body"
    Cms::Page.addon "cms/file"
    Cms::Page.addon "cms/release"
    
    Cms::Node.plugin "cms/node"
    Cms::Node.plugin "cms/page"
    Cms::Part.plugin "cms/free"
    Cms::Part.plugin "cms/node"
    Cms::Part.plugin "cms/page"
    Cms::Part.plugin "cms/tabs"
    Cms::Part.plugin "cms/crumb"
  end
end
