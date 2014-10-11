class Cms::Task::NodesController < ApplicationController
  include SS::Task::BaseFilter
  include Cms::ReleaseFilter::Page

  before_action :set_params

  private
    def set_params
      @site  = params[:site]
      @node  = params[:node]
      @limit = params[:limit] || 100
      @limit = @limit.to_i
    end

  public
    def generate
      task.log "# #{@site.name}"
      #return unless @cur_site.serve_static_file?

      nodes = Cms::Node.site(@site).public
      nodes = nodes.where(filename: /^#{@node.filename}\/?$/) if @node

      nodes.each { |node| route_node node }
    end

  private
    def route_node(node)
      return unless node.public_node?

      cname = node.route.sub("/", "/task/node/").camelize.pluralize + "Controller"
      klass = cname.constantize rescue nil
      return if klass.nil? || klass.to_s != cname

      cont = klass.new
      #cont.generate task: task, node: node.becomes_with_route
      cont.params   = ActionController::Parameters.new task: task, node: node.becomes_with_route
      cont.request  = ActionDispatch::Request.new "rack.input" => "", "REQUEST_METHOD" => "GET"
      cont.response = ActionDispatch::Response.new
      cont.process :generate

      generate_node_pages(node.pages.public)
    end

    def generate_node_pages(pages)
      return if pages.size > @limit

      pages.each do |page|
        task.count
        next unless page.public_node?

        if generate_page page.becomes_with_route
          task.log page.url
        end
      end
    end
end
