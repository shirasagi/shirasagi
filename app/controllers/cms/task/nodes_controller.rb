# coding: utf-8
class Cms::Task::NodesController < ApplicationController
  include Cms::ReleaseFilter::Page

  public
   def generate(opts)
      @task = opts[:task]
      #return unless @cur_site.serve_static_file?

      Cms::Node.site(opts[:site]).public.each do |node|
        generate_node node
      end
    end

    def generate_with_node(opts)
      @task = opts[:task]
      #return unless @cur_site.serve_static_file?

      Cms::Node.site(opts[:site]).where(filename: /^#{opts[:node].filename}\/?$/).public.each do |node|
        generate_node node
      end
    end

  private
    def generate_node(node)
      return unless node.public_node?

      cname = node.route.sub("/", "/task/node/").camelize.pluralize + "Controller"
      klass = cname.constantize rescue nil
      return if klass.nil? || klass.to_s != cname
      klass.new.generate task: @task, node: node.becomes_with_route

      generate_pages(node.pages)
    end

    def generate_pages(pages)
      return if pages.size > 50

      pages.each do |page|
        next unless page.public_node?
        @task.log page.url if @task
        generate_page page.becomes_with_route
      end
    end
end
