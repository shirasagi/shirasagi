class Cms::Transaction::Unit::Generation < Cms::Transaction::Unit::Base
  include Cms::Addon::Transaction::Filename
  include SS::RescueWith

  def type
    "generation"
  end

  def rescue_p
    proc do |exception|
      exception_backtrace(exception) do |message|
        @task.log message
        Rails.logger.error message
      end
    end
  end

  def each_item_with_rescue(&block)
    each_item do |item|
      rescue_with(rescue_p: rescue_p) do
        yield item
      end
    end
  end

  def each_item(&block)
    items = Cms::Node.site(site).in(filename: filenames).to_a
    items += Cms::Page.site(site).in(filename: filenames).to_a

    items = filenames.map do |path|
      items.find { |item| item.filename == path }
    end.compact
    items.each(&block)
  end

  def execute_main
    @task.performance.header(name: "generate node performance log at #{Time.zone.now.iso8601}")
    @task.performance.collect_site(@site) do
      if @site.generate_locked?
        @task.log(@site.t(:generate_locked))
        return
      end

      each_item_with_rescue do |item|
        if item.is_a?(Cms::Model::Node)
          generate_node(item)
        else
          generate_page(item)
        end
      end
    end
  end

  def generate_node(node)
    return unless node
    return unless node.public?
    return unless node.public_node?
    return if node.try(:any_ancestor_nodes_for_member_enabled?)

    @task.performance.collect_node(node) do
      # ex: "article/page" => "article/agents/nodes/page"
      cont = node.route.sub("/", "/agents/nodes/")
      return if SS::Agent.invoke_action(
        cont, :generate,
        task: @task, cur_site: @site, cur_node: node,
        cur_path: "#{node.url}index.html", cur_main_path: "#{node.url.sub(@site.url, "/")}index.html"
      )

      # ex: "article/page" => "article/agents/tasks/node/pages"
      cont = node.route.sub("/", "/agents/tasks/node/").pluralize
      SS::Agent.invoke_action(cont, :generate, task: @task, site: @site, node: node)
    end
  end

  def generate_page(page)
    @task.performance.collect_page(page) do
      result = page.generate_file(task: @task)

      @task.log page.url if result
    end
  end
end
