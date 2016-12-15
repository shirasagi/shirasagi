module Cms::PublicFilter::Node
  extend ActiveSupport::Concern
  include Cms::PublicFilter::Layout

  private
    def init_context
      self.params   = ActionController::Parameters.new
      self.request  = ActionDispatch::Request.new("rack.input" => "", "REQUEST_METHOD" => "GET")
      self.response = ActionDispatch::Response.new
    end

    def find_node(path)
      node = Cms::Node.site(@cur_site).in_path(path).sort(depth: -1).to_a.first
      return unless node
      @preview || node.public? ? node.becomes_with_route : nil
    end

    def render_node(node)
      dump(@cur_site.name)
      dump("render_node")
      dump([node, @cur_path, @cur_main_path])
      rest = @cur_main_path.sub(/^\/#{node.filename}/, "").sub(/\/index\.html$/, "")
      path = "/.s#{@cur_site.id}/nodes/#{node.route}#{rest}"
      spec = recognize_agent path
      return unless spec

      @cur_node = node
      controller = node.route.sub(/\/.*/, "/agents/#{spec[:cell]}")

      agent = new_agent controller
      agent.controller.params.merge! spec
      agent.render spec[:action]
    end

  public
    def generate_node(node, opts = {})
      path = opts[:url] || "#{node.filename}/index.html"
      return if Cms::Page.site(node.site).and_public.filename(path).first

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
        raise e unless Rails.env.producton?
      end

      if response.content_type == "text/html" && node.layout
        html = render_to_string inline: render_layout(node.layout), layout: "cms/page"
      else
        html = response.body
      end

      file = opts[:file] || "#{node.path}/index.html"
      write_file node, html, file: file
    end

    def generate_node_with_pagination(node, opts = {})
      if generate_node node
        @task.log "#{node.url}index.html" if @task
      end

      max = opts[:max] || 9999
      num = max

      2.upto(max) do |i|
        file = "#{node.path}/index.p#{i}.html"

        if generate_node node, file: file, params: { page: i }
          @task.log "#{node.url}index.p#{i}.html" if @task
        end

        if !@exists
          num = i
          break
        end
      end

      num.upto(max) do |i|
        file = "#{node.path}/index.p#{i}.html"
        break unless Fs.exists?(file)
        Fs.rm_rf file
      end
    end
end
