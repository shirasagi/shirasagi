# coding: utf-8
module Cms::Parts::Free
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Cms::Part::Free
  end
  
  class ViewCell < Cell::Rails
    include Cms::PartFilter::ViewCell
    
    def index
      @cur_part.html
    end
  end
end
