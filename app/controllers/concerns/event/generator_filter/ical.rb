module Event::GeneratorFilter::Ical
  extend ActiveSupport::Concern
  include Event::IcalHelper

  private

  def render_node_ical(node)
    rest = @cur_main_path.sub(/^\/#{node.filename}/, "").sub(/\/index\.html$/, "")
    path = "/.s#{@cur_site.id}/nodes/#{node.route}#{rest}"
    spec = recognize_agent path
    return unless spec

    @cur_node = node
    controller = node.route.sub(/\/.*/, "/agents/#{spec[:cell]}")

    @agent = new_agent controller
    @agent.controller.params.merge! spec
    @agent.render spec[:action]
  end

  def generate_node_ical(node, opts = {})
    path = opts[:url] || "#{node.filename}/index.html"
    return if Cms::Page.site(node.site).and_public.filename(path).first
    return unless node.serve_static_file?

    @cur_site      = node.site
    @cur_path      = opts[:url] || node.url
    @cur_main_path = @cur_path.sub(@cur_site.url, "/")
    @csrf_token    = false

    params.merge! opts[:params] if opts[:params]

    begin
      @exists = true
      response.body = render_node_ical node
      response.content_type ||= "text/html"
    rescue StandardError => e
      @exists = false
      return if e.to_s == "404"
      return if e.is_a? Mongoid::Errors::DocumentNotFound
      raise e unless Rails.env.producton?
    end

    if response.content_type == "text/html" && node.layout
      html = render_to_string html: render_layout(node.layout).html_safe, layout: "cms/page"
    else
      html = response.body
    end

    file = opts[:file] || "#{node.path}/index.html"
    write_file node, html, file: file
    write_file node, event_to_ical(@agent.controller.items), file: file.sub(/\.html$/, '.ics')
  end
end
