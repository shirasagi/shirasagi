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

    nodes = Cms::Node.site(@site)
    nodes = nodes.where(filename: /^#{::Regexp.escape(@node.filename)}(\/|$)/) if @node
    ids   = nodes.pluck(:id)

    ids.each do |id|
      node = Cms::Node.site(@site).where(id: id).first
      next unless node

      node = node.becomes_with_route
      release_node(node)

      next unless node.public?
      next unless node.public_node?

      cont = node.route.sub("/", "/agents/tasks/node/").camelize.pluralize
      cname = cont + "Controller"

      agent = SS::Agent.new cont rescue nil
      next if agent.blank? || agent.controller.class.to_s != cname
      agent.controller.instance_variable_set :@task, @task
      agent.controller.instance_variable_set :@site, @site
      agent.controller.instance_variable_set :@node, node
      agent.invoke :generate

      #generate_node_pages node
    end
  end

  def generate_root_pages
    pages = Cms::Page.site(@site).and_public.where(filename: /^[^\/]+$/, depth: 1)
    ids   = pages.pluck(:id)

    ids.each do |id|
      @task.count
      page = Cms::Page.where(id: id).first
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

  def release_node(node)
    return if !(node.respond_to?(:close_date) && node.respond_to?(:release_date))

    now = Time.zone.now
    if node.public? && node.close_date && now >= node.close_date
      node.state = "closed"
      node.close_date = nil
    elsif node.state == "ready" && node.release_date && now >= node.release_date
      node.state = "public"
      node.release_date = nil
    else
      return
    end

    if node.save
      @task.log "release update #{node.name} "
    else
      @task.log "release update failed: " + node.errors.full_messages.join(', ')
    end
  end
end
