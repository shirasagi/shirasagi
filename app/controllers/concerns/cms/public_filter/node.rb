module Cms::PublicFilter::Node
  extend ActiveSupport::Concern
  include Cms::PublicFilter::Layout

  private

  def init_context
    self.params   = ActionController::Parameters.new
    self.request  = ActionDispatch::Request.new("rack.input" => "", "REQUEST_METHOD" => "GET")
    self.response = ActionDispatch::Response.new

    @site.reload if @site.changed?
    @node.reload if @node.changed?
  end

  def find_node(path)
    node = Cms::Node.site(@cur_site).in_path(path).order_by(depth: -1).to_a.first
    return unless node
    @preview || node.public? ? node.becomes_with_route : nil
  end

  def render_node(node)
    rest = @cur_main_path.sub(/^\/#{::Regexp.escape(node.filename)}/, "").sub(/\/index\.html$/, "")
    path = "/.s#{@cur_site.id}/nodes/#{node.route}#{rest}"
    spec = recognize_agent path
    return unless spec

    @cur_node = node
    controller = node.route.sub(/\/.*/, "/agents/#{spec[:cell]}")

    agent = new_agent controller
    agent.controller.request.path_parameters.merge! spec
    agent.controller.params.merge! spec
    agent.render spec[:action]
  end

  def render_layout_with_pagination_cache(layout, cache_key)
    @layout_cache ||= {}

    # no cache
    if cache_key.nil?
      return render_to_string html: render_layout(layout).html_safe, layout: "cms/page"
    end

    # use cache
    if @layout_cache[cache_key]
      return @layout_cache[cache_key].sub(/<!-- layout_yield -->/, response.body)
    end

    # set cache
    html = render_to_string html: render_layout(layout).html_safe, layout: "cms/page"
    @layout_cache[cache_key] = html.sub(/(<!-- layout_yield -->).*?<!-- \/layout_yield -->/m, '\\1')

    html
  end

  def delete_layout_cache(cache_key)
    @layout_cache.delete(cache_key) if @layout_cache
  end

  public

  def generate_node(node, opts = {})
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
      response.body = render_node node
      response.content_type ||= "text/html"
    rescue StandardError => e
      @exists = false
      return if e.to_s == "404"
      return if e.is_a? Mongoid::Errors::DocumentNotFound
      raise e
    end

    if response.content_type == "text/html" && node.layout
      html = render_layout_with_pagination_cache(node.layout, opts[:cache])
    else
      html = response.body
    end

    file = opts[:file] || "#{node.path}/index.html"
    write_file node, html, file: file
  end

  def generate_node_with_pagination(node, opts = {})
    if generate_node(node, cache: node.filename)
      @task.log "#{node.url}index.html" if @task
    end

    max = opts[:max] || 9999
    num = max

    2.upto(max) do |i|
      file = "#{node.path}/index.p#{i}.html"

      if generate_node(node, file: file, params: { page: i }, cache: node.filename)
        @task.log "#{node.url}index.p#{i}.html" if @task
      end

      if !@exists
        num = i
        break
      end
    end

    delete_layout_cache(node.filename)

    num.upto(max) do |i|
      file = "#{node.path}/index.p#{i}.html"
      break unless Fs.exists?(file)
      Fs.rm_rf file
    end
  end
end
