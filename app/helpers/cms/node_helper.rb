# coding: utf-8
module Cms::NodeHelper
  def node_navi(opts = {}, &block)
    h  = []
    
    if block_given?
      h << capture(&block)
    end
    
    h << render(partial: "cms/node/main/node_navi")
    h << render(partial: "cms/node/main/modules")
    #h << render(partial: "cms/main/navi")
    h.join.html_safe
  end
end
