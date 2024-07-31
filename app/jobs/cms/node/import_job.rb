class Cms::Node::ImportJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:import_nodes"

  def perform(ss_file_id)
    file = SS::File.find(ss_file_id)
    importer = Cms::Node::Importer.new(site, node, user)
    importer.import(file, task: task)
    ensure
      file.destroy rescue nil
    # # TODO: Implement import
    # # Create and update items that kind of Cms::Node.
    # # Remove the comments in the example below and output the logs in Japanese.
    # task.log "This job running under the #{site.name}"
    # task.log "and also running under the #{node.name}" if node
    # task.log "#{user.name} started import nodes from #{file.name}"
  end

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond[:node_id] = node_id
    cond
  end
end
