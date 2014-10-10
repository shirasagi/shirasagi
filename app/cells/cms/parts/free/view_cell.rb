module Cms::Parts::Free
  class ViewCell < Cell::Rails
    include Cms::PartFilter::ViewCell

    def index
      @cur_part.html
    end
  end
end
