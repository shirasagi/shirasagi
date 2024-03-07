class KeyVisual::Agents::Parts::SwiperSlideController < ApplicationController
  include Cms::PartFilter::View

  def index
    @node = @cur_part.parent
    return head :ok unless @node

    @items = Cms::Page.site(@cur_site).node(@node).and_public(@cur_date)
    @items = @items.order_by(order: 1).limit(@cur_part.limit)

    stylesheet("swiper", media: 'all')
    javascript("swiper", defer: true)
  end
end
