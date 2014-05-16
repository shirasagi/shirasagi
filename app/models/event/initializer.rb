# coding: utf-8
module Event
  class Initializer
    Cms::Page.addon "event/date"
    
    Cms::Node.plugin "event/page"
  end
end
