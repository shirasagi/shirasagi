module Cms::GeneratorFilter::Rss
  extend ActiveSupport::Concern

  private

  def _generate_node_rss(node, opts = {})
    @cur_path   = opts[:url] || "#{node.url}rss.xml"
    @cur_site   = node.site
    @csrf_token = false

    if @cur_site.subdir.present?
      @cur_main_path = @cur_path.sub(/^\/#{@cur_site.subdir}/, "")
    else
      @cur_main_path = @cur_path.dup
    end

    params.merge! opts[:params] if opts[:params]

    begin
      @exists = true
      response.body = render_node(node) || ''
      response.content_type ||= "application/rss+xml"
    rescue StandardError => e
      @exists = false
      return if e.to_s == "404"
      return if e.is_a? Mongoid::Errors::DocumentNotFound
      raise e
    end

    if response.content_type == "text/html" && node.layout
      html = render_to_string html: render_layout(node.layout).html_safe, layout: "cms/page"
    else
      html = response.body
    end

    file = opts[:file] || "#{node.path}/rss.xml"
    Fs.write_data_if_modified file, html
  end

  def generate_node_rss(node, opts = {})
    path = opts[:url] || "#{node.filename}/index.html"
    return if Cms::Page.site(node.site).and_public.filename(path).first
    return unless node.serve_static_file?

    node_perf_log(node, rss: 1) do
      _generate_node_rss(node, opts)
    end
  end
end
