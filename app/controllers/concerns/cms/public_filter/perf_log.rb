module Cms::PublicFilter::PerfLog
  extend ActiveSupport::Concern

  def node_perf_log(node, scope = {}, &block)
    if @task.blank?
      return yield
    end

    @task.performance.collect_node(node, scope, &block)
  end

  def layout_perf_log(layout, scope = {}, &block)
    if @task.blank?
      return yield
    end

    @task.performance.collect_layout(layout, scope, &block)
  end

  def part_perf_log(part, scope = {}, &block)
    if @task.blank?
      return yield
    end

    @task.performance.collect_part(part, scope, &block)
  end
end
