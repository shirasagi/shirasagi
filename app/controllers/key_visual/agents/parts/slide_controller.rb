class KeyVisual::Agents::Parts::SlideController < ApplicationController
  include Cms::PartFilter::View

  def index
    @node = @cur_part.parent
    return render nothing: true unless @node

    @items = KeyVisual::Image.site(@cur_site).node(@node).and_public(@cur_date).order_by(order: 1)
  end
end
