class Cms::Node::DestroyJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:destroy_nodes"
  self.controller = Cms::Agents::Tasks::NodesController
  self.action = :destroy

  def perform(*args)
    options = args.extract_options!
    options.symbolize_keys!
    selected_ids = args.first

    task.process self.class.controller, self.class.action, { site: site, node: node, user: user, selected_ids: selected_ids }
  end

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond[:node_id] = node_id
    cond
  end
end
