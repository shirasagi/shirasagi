class Member::Agents::Parts::PhotoSlideController < ApplicationController
  include Cms::PartFilter::View

  def render_other_site_items
    begin
      uri = ::Addressable::URI.parse(@cur_part.node_url)
      site = Cms::Site.find_by_domain(uri.host, uri.path)
      site ||= Cms::Site.find_by_domain("#{uri.host}:#{uri.port}", uri.path)
      filename = uri.path.sub(site.url, "").sub(/\/$/, "")
      node = Member::Node::Photo.site(site).where(filename: filename).first

      raise "404" unless site && node
    rescue => e
      Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      return head :ok
    end

    @items = Member::Photo.site(site).
      node(node).
      and_public(@cur_date).
      slideable.
      order_by(slide_order: 1)
  end

  def render_items
    node = @cur_part.parent
    return head :ok unless node

    @items = Member::Photo.site(@cur_site).
      node(node).
      and_public(@cur_date).
      slideable.
      order_by(slide_order: 1)
  end

  def index
    if @cur_part.node_url.present?
      render_other_site_items
    else
      render_items
    end
  end
end
