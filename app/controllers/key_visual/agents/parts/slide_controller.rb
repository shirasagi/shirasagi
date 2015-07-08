class KeyVisual::Agents::Parts::SlideController < ApplicationController
  include Cms::PartFilter::View

  public
    def index
      @node = @cur_part.parent
      return render nothing: true unless @node

      sort = @cur_part.becomes_with_route.sort_hash
      @random = sort[:random]

      @items = KeyVisual::Image.site(@cur_site).node(@node).public(@cur_date).order_by(sort)
    end
end
