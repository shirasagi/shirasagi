module Job::Cms::GeneratorFilter
  extend ActiveSupport::Concern
  include Job::SS::TaskFilter

  included do
    self.task_class = Cms::Task
  end

  def perform(opts = {})
    task.process self.class.controller, self.class.action, opts.merge(site: site, node: node)
  end

  private

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond[:node_id] = node_id
    cond
  end
end
