class Cms::Agents::Parts::TabsController < ApplicationController
  include Cms::PartFilter::View
  include Cms::PublicFilter::Agent
  helper Cms::TabsHelper

  def index
    @tabs = []
    save_site = @cur_site
    save_node = @cur_node

    @cur_part.interpret_conditions(site: @cur_site, default_location: :never, request_dir: false) do |site, content_or_path|
      if content_or_path.is_a?(Cms::Content) || content_or_path == :root_contents || content_or_path.end_with?("*")
        # - default content is not supported
        # - root content is not supported
        # - wildcard is not supported
        next
      end

      node = Cms::Node.site(site).and_public(@cur_date).filename(content_or_path).first
      next unless node

      @tabs << tab = { name: node.name, url: node.url, rss: nil, pages: [] }

      spec, rss_spec = recognize_node_content(site, node, content_or_path)
      next unless spec

      if node.class.method_defined?(:condition_hash)
        pages = Cms::Page.public_list(site: site, node: node, date: @cur_date)
      else
        pages = Cms::Page.site(site).and_public(@cur_date).node(node)
      end
      pages = pages ? pages.order_by(released: -1).limit(@cur_part.limit) : []
      tab[:pages] = pages.to_a
      tab[:rss] = "#{node.url}rss.xml" if rss_spec
    end

    render
  end

  private

  def recognize_node_content(site, node, content_or_path)
    rest = content_or_path.sub(/^#{::Regexp.escape(node.filename)}/, "")
    path = "/.s#{site.id}/nodes/#{node.route}#{rest}"
    spec = recognize_agent path, method: "GET"

    rss_path = "#{path}/rss.xml"
    rss_spec = recognize_agent rss_path, method: "GET"

    [spec, rss_spec]
  end
end
