class Inquiry::Agents::Tasks::Node::FormsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate_inquiry_node(node, opts = {})
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
    html.gsub!(/<\s*input\s+type="hidden"\s+name="authenticity_token"\s+value=".+?"\s*\/>/, '')

    file = opts[:file] || "#{node.path}/index.html"
    write_file node, html, file: file
  end

  def generate
    if generate_inquiry_node @node
      @task.log "#{@node.url}index.html" if @task
    end
  end
end
