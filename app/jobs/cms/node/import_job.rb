class Cms::Node::ImportJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:import_nodes"

  def perform(ss_file_id)
    file = SS::File.find(ss_file_id)
    importer = Cms::NodeImporter.new(site, node, user)
    importer.import(file, task: task)
  ensure
    file.destroy if file
  end

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond[:node_id] = node_id
    cond
  end
end
