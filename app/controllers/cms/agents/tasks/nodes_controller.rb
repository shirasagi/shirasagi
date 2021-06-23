class Cms::Agents::Tasks::NodesController < ApplicationController
  include Cms::PublicFilter::Node
  include SS::RescueWith

  before_action :set_params
  PER_BATCH = 100

  private

  def set_params
  end

  def rescue_p
    proc do |exception|
      exception_backtrace(exception) do |message|
        @task.log message
        Rails.logger.error message
      end
    end
  end

  def each_node(&block)
    nodes = base_criteria = Cms::Node.site(@site).and_public
    nodes = nodes.where(filename: /^#{::Regexp.escape(@node.filename)}(\/|$)/) if @node
    all_ids = nodes.pluck(:id)
    all_ids.each_slice(PER_BATCH) do |ids|
      base_criteria.in(id: ids).to_a.each(&block)
    end
  end

  def each_node_with_rescue(&block)
    each_node do |node|
      rescue_with(rescue_p: rescue_p) do
        yield node
      end
    end
  end

  def each_root_pages(&block)
    base_criteria = Cms::Page.site(@site).and_public
    pages = base_criteria.where(filename: /^[^\/]+$/, depth: 1)
    all_ids = pages.pluck(:id)
    all_ids.each_slice(PER_BATCH) do |ids|
      Cms::Page.in(id: ids).to_a.each(&block)
    end
  end

  def each_root_pages_with_rescue(&block)
    each_root_pages do |page|
      rescue_with(rescue_p: rescue_p) do
        yield page
      end
    end
  end

  public

  def generate
    @task.log "# #{@site.name}"
    @task.performance.header(name: "generate node performance log at #{Time.zone.now.iso8601}")
    @task.performance.collect_site(@site) do
      if @site.generate_locked?
        @task.log(@site.t(:generate_locked))
        return
      end

      generate_root_pages unless @node

      each_node_with_rescue do |node|
        next unless node

        node = node.becomes_with_route
        next unless node.public?
        next unless node.public_node?

        @task.performance.collect_node(node) do
          cont = node.route.sub("/", "/agents/tasks/node/").camelize.pluralize
          cname = cont + "Controller"

          agent = SS::Agent.new cont rescue nil
          next if agent.blank? || agent.controller.class.to_s != cname
          agent.controller.instance_variable_set :@task, @task
          agent.controller.instance_variable_set :@site, @site
          agent.controller.instance_variable_set :@node, node
          agent.invoke :generate
        end
      end
    end
  end

  def generate_root_pages
    each_root_pages_with_rescue do |page|
      @task.count
      next unless page

      @task.performance.collect_page(page) do
        page = page.becomes_with_route
        result = page.generate_file(task: @task)

        @task.log page.url if result
      end
    end
  end

  def generate_node_pages(node)
    pages = node.pages.and_public

    pages.order_by(id: 1).find_each(batch_size: PER_BATCH) do |page|
      rescue_with(rescue_p: rescue_p) do
        @task.count

        @task.performance.collect_page(page) do
          page = page.becomes_with_route
          result = page.generate_file(task: @task)

          @task.log page.url if result
        end
      end
    end
  end
end
