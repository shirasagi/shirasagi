class Member::Agents::Parts::PhotoSlideController < ApplicationController
  include Cms::PartFilter::View

  def index
    begin
      if @cur_part.node_url.present?
        require "uri"
        uri      = URI.parse(@cur_part.node_url)
        host     = uri.host
        filename = uri.path.sub(/^\//, "").sub(/\/$/, "")
        site     = Cms::Site.in(domains: host).first
        node     = Member::Node::Photo.site(site).where(filename: filename).first

        raise "404" unless site && node

        @items = Member::Photo.site(site).
          node(node).
          and_public(@cur_date).
          slideable.
          order_by(slide_order: 1)

        render :full_url_index
        return
      end
    rescue
    end

    @node = @cur_part.parent
    return render nothing: true unless @node

    @items = Member::Photo.site(@cur_site).
      node(@node).
      and_public(@cur_date).
      slideable.
      order_by(slide_order: 1)
  end
end
