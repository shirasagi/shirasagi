module Cms::PublicFilter::FindContent
  extend ActiveSupport::Concern
  include Cms::PublicFilter::Agent

  def find_page(site, path)
    filename = path.delete_prefix(site.url)
    page = Cms::Page.site(site).filename(filename).first
    return unless page

    page.becomes_with_route
  end

  def find_node(site, path)
    filename = path.delete_prefix(site.url)

    node = Cms::Node.site(site).in_path(filename).order_by(depth: -1).to_a.first
    return unless node

    rest = filename.delete_prefix(node.filename).sub(/\/(index\.html)?$/, "")
    path = "/.s#{site.id}/nodes/#{node.route}#{rest}"
    spec = recognize_agent(path, method: "GET")
    return unless spec

    node.becomes_with_route
  end

  def find_content(site, path)
    find_page(site, path) || find_node(site, path)
  end
end
