class ImageMap::Agents::Pages::PageController < ApplicationController
  include Cms::PageFilter::View

  def pages
    return public_pages unless @preview
    preview_pages
  end

  def public_pages
    ImageMap::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end

  def preview_pages
    cond = []
    cond << { id: { "$ne" => @cur_page.master_id } } if @cur_page.master
    cond << { "$or" => [public_pages.selector, { id: @cur_page.id }] }
    ImageMap::Page.and(cond)
  end

  public

  def index
    @cur_node = @cur_page.parent
    return if @cur_node.nil?

    @items = pages.order_by(order: 1).limit(@cur_node.limit).to_a
    @image = @cur_node.image
    @usemap = "image-map-#{@cur_node.id}"
  end
end
