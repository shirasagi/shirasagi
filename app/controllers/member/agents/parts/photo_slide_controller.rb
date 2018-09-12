class Member::Agents::Parts::PhotoSlideController < ApplicationController
  include Cms::PartFilter::View

  def index
    begin
      if @cur_part.node_url.present?
        require "uri"
        uri = URI.parse(@cur_part.node_url)
        Member::Node::Photo.each do |item|
          next if item.url != uri.path || !item.site.domains.include?(uri.host)
          @site = item.site
          @node = item
        end

        raise "404" unless @site && @node

        @items = Member::Photo.site(@site).
          node(@node).
          and_public(@cur_date).
          slideable.
          order_by(slide_order: 1)

        render :full_url_index
        return
      end
    rescue
    end

    @node = @cur_part.parent
    return head :ok unless @node

    @items = Member::Photo.site(@cur_site).
      node(@node).
      and_public(@cur_date).
      slideable.
      order_by(slide_order: 1)
  end
end
