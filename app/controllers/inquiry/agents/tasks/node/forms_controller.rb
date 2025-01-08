class Inquiry::Agents::Tasks::Node::FormsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate_inquiry_node(node, opts = {})
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
      return if SS.not_found_error?(e)
      raise e
    end

    if response.media_type == "text/html" && node.layout
      html = render_to_string html: render_layout(node.layout).html_safe, layout: "cms/page"
    else
      html = response.body
    end
    html.gsub!(/<\s*input\s+type="hidden"\s+name="authenticity_token"\s+value=".+?"\s*\/>/, '')

    file = opts[:file] || "#{node.path}/index.html"
    Fs.write_data_if_modified file, html
  end

  def generate
    #@node.save # save for release date

    if !@node.serve_static_file?
     file = ::File.join(@node.path, "index.html")
     File.delete(file) if File.exist?(file)
    end

    if generate_inquiry_node @node
      @task.log "#{@node.url}index.html" if @task
    end
  end
end
