class Cms::Agents::Nodes::PhotoAlbumController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::ForMemberFilter::Node
  helper Cms::ListHelper

  #ALLOWED_EXTS = %w(gif png jpg jpeg bmp).freeze

  def index
    condition_hash = @cur_node.condition_hash
    if @cur_node.conditions.blank? && @cur_node.parent.respond_to?(:condition_hash)
      condition_hash = @cur_node.parent.condition_hash
    end

    pages = Cms::Page.site(@cur_site).
      and_public(@cur_date).
      where(condition_hash)

    file_ids = pages.pluck(:file_ids).flatten.compact
    images = SS::File.in(id: file_ids).where(content_type: /^image\//).to_a
    images = images.index_by(&:id)

    items = []
    pages.each do |page|
      page.file_ids.each do |file_id|
        image = images[file_id]
        next unless image
        items << [page, image]
      end
    end

    @items = Kaminari.paginate_array(items).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination @items
  end
end
