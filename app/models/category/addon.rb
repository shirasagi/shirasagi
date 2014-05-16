# coding: utf-8
module Category::Addon
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern
    
    set_order 300
  end
end
