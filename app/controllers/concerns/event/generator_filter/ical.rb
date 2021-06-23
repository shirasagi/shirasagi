module Event::GeneratorFilter::Ical
  extend ActiveSupport::Concern

  private

  def generate_node_ical(node, opts = {})
    path = opts[:url] || "#{node.filename}/index.html"
    return if Cms::Page.site(node.site).and_public.filename(path).first
    return unless node.serve_static_file?

    @cur_path   = opts[:url] || "#{node.url}index.ics"
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
      response.body = render_node node
      response.content_type ||= "text/calendar"
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

    file = opts[:file] || "#{node.path}/index.ics"
    Fs.write_data_if_modified file, html
  end
end
