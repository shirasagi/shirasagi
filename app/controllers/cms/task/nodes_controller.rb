# coding: utf-8
class Cms::Task::NodesController < ApplicationController
  include Cms::ReleaseFilter::Page

  public
    def generate(opts)
      @task = opts[:task]
      @site = opts[:site]
      @limit = (opts[:limit] || 100).to_i

      @task.log "# #{@site.name}"
      #return unless @cur_site.serve_static_file?

      nodes = Cms::Node.site(opts[:site]).public
      nodes.each { |node| route_node node }
    end

    def generate_with_node(opts)
      @task = opts[:task]
      @site = opts[:site]
      @limit = (opts[:limit] || 100).to_i

      @task.log "# #{@site.name}"
      #return unless @cur_site.serve_static_file?

      nodes = Cms::Node.site(opts[:site]).where(filename: /^#{opts[:node].filename}\/?$/).public
      nodes.each { |node| route_node node }
    end

  private
    def route_node(node)
      return unless node.public_node?

      cname = node.route.sub("/", "/task/node/").camelize.pluralize + "Controller"
      klass = cname.constantize rescue nil
      return if klass.nil? || klass.to_s != cname
      klass.new.generate task: @task, node: node.becomes_with_route

      generate_pages(node.pages.public)
    end

    def generate_pages(pages)
      return if pages.size > @limit

      pages.each do |page|
        @task += 1
        next unless page.public_node?
        if generate_page page.becomes_with_route
          @task.log page.url
        end
      end
    end
end
