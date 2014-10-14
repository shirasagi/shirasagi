module Cms::GenerateFilter::Node
  extend ActiveSupport::Concern
  include Cms::PublicFilter::Layout

  public
    def generate_node(node, opts = {})
      return if Cms::Page.site(node.site).public.where(filename: "#{node.filename}/index.html").first

      @cur_path   = node.url
      @cur_site   = node.site
      @cur_layout = node.layout
      @csrf_token = false

      locals = opts[:params] || {}
      locals[:format] ||= "html"

      agent = SS::Agent.new self.class
      self.params   = agent.controller.params.merge(locals)
      self.request  = agent.controller.request
      self.response = agent.controller.response

      response.body = render_node node
      dump response.body

      return

      self.params   = ActionController::Parameters.new params.merge(locals)
      #self.request  = ActionDispatch::Request.new method: "GET"
      #self.response = ActionDispatch::Response.new

      html = render_node(node, method: "GET")
      return unless html
      html = render_to_string inline: render_layout(html), layout: "cms/page" if @cur_layout

      file = opts[:file] || "#{node.path}/index.html"

      write_file node, html, file: file
    end

    def generate_node_with_pagination(node)
      task.log "#{node.url}index.html" if generate_node node

      return

      max = 9999
      num = max

      2.upto(max) do |i|
        file = "#{node.path}/index.p#{i}.html"
        begin
          if generate_node node, file: file, params: { page: i }
            task.log "#{node.url}index.p#{i}.html" if task
          end
        rescue StandardError => e
          raise e if "#{e}" != "404"
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
