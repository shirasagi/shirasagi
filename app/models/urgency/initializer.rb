# coding: utf-8
module Urgency
  class Initializer
    Cms::Node.plugin "urgency/layout"
    
    Urgency::Node::Layout.addon "urgency/layout"
    #addon "urgency/layout"
  end
end
