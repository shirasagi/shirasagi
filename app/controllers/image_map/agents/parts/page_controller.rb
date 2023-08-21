class ImageMap::Agents::Parts::PageController < ApplicationController
  include Cms::PartFilter::View

  private

  def pages
    ImageMap::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end

  public

  def index
    @cur_node = @cur_part.parent
    return if @cur_node.nil?

    @items = pages.order_by(order: 1).limit(@cur_node.limit).to_a
    @image = @cur_node.image
    @usemap = "image-map-#{@cur_node.id}"
  end
end
