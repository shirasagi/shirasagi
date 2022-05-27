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

  def filter_by_segment(ids)
    return ids if @segment.blank?

    keys = @site.generate_node_segments
    return ids if keys.blank?
    return ids if keys.index(@segment).nil?

    @task.log "# filter by #{@segment}"
    ids.select { |id| (id % keys.size) == keys.index(@segment) }
  end

  def each_node(&block)
    nodes = base_criteria = Cms::Node.site(@site)
    nodes = nodes.where(filename: /^#{::Regexp.escape(@node.filename)}(\/|$)/) if @node
    all_ids = nodes.pluck(:id)
    all_ids = filter_by_segment(all_ids)
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
    all_ids = filter_by_segment(all_ids)
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

  def release_node(node)
    node.cur_site = @site

    if node.public?
      node.state = "closed"
      node.close_date = nil
    elsif node.state == "ready"
      node.state = "public"
      node.release_date = nil
    end

    if node.save
      @task.log "release update #{node.name} - #{node.state} "
    else
      @task.log "release update failed: " + node.errors.full_messages.join(', ')
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
        next unless node.public?
        next unless node.public_node?

        @task.performance.collect_node(node) do
          # ex: "article/page" => "article/agents/nodes/page"
          cont = node.route.sub("/", "/agents/nodes/")
          next if SS::Agent.invoke_action(
            cont, :generate,
            task: @task, cur_site: @site, cur_node: node,
            cur_path: "#{node.url}index.html", cur_main_path: "#{node.url.sub(@site.url, "/")}index.html"
          )

          # ex: "article/page" => "article/agents/tasks/node/pages"
          cont = node.route.sub("/", "/agents/tasks/node/").pluralize
          SS::Agent.invoke_action(cont, :generate, task: @task, site: @site, node: node)
        end
      end
    end
  end

  def generate_root_pages
    each_root_pages_with_rescue do |page|
      @task.count
      next unless page

      @task.performance.collect_page(page) do
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
          result = page.generate_file(task: @task)

          @task.log page.url if result
        end
      end
    end
  end

  def release
    @task.log "# #{@site.name}"

    time = Time.zone.now

    cond = [
      { state: "ready", release_date: { "$lte" => time } },
      { state: "public", close_date: { "$lte" => time } }
    ]
    nodes = Cms::Node.site(@site).where("$or" => cond)

    ids   = nodes.pluck(:id)
    @task.total_count = ids.size

    ids.each do |id|
      rescue_with(rescue_p: rescue_p) do
        @task.count
        node = Cms::Node.site(@site).or(cond).where(id: id).first
        next unless node

        release_node node.becomes_with_route
      end
    end
  end
end
