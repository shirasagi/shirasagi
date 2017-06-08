class Cms::Agents::Tasks::NodesController < ApplicationController
  include Cms::PublicFilter::Node

  before_action :set_params
  PER_BATCH = 100

  private

  def set_params
    #
  end

  public

  def generate
    @task.log "# #{@site.name}"

    generate_root_pages unless @node

    nodes = Cms::Node.site(@site).and_public
    nodes = nodes.where(filename: /^#{@node.filename}\/?$/) if @node
    ids   = nodes.pluck(:id)

    ids.each do |id|
      node = Cms::Node.site(@site).and_public.where(id: id).first
      next unless node
      next unless node.public?
      next unless node.public_node?

      node  = node.becomes_with_route
      cname = node.route.sub("/", "/agents/tasks/node/").camelize.pluralize + "Controller"
      klass = cname.constantize rescue nil
      next if klass.nil? || klass.to_s != cname

      agent = SS::Agent.new klass
      agent.controller.instance_variable_set :@task, @task
      agent.controller.instance_variable_set :@site, @site
      agent.controller.instance_variable_set :@node, node
      agent.invoke :generate

      #generate_node_pages node
    end
  end

  def generate_root_pages
    pages = Cms::Page.site(@site).and_public.where(depth: 1)
    ids   = pages.pluck(:id)

    ids.each do |id|
      @task.count
      page = Cms::Page.site(@site).and_public.where(depth: 1).where(id: id).first
      next unless page
      @task.log page.url if page.becomes_with_route.generate_file
    end
  end

  def generate_node_pages(node)
    pages = node.pages.and_public

    pages.order_by(id: 1).find_each(batch_size: PER_BATCH) do |page|
      @task.count
      @task.log page.url if page.becomes_with_route.generate_file
    end
  end
end
