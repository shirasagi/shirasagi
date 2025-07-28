class Article::Page::ImportJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "article:import_pages"

  def perform(ss_file_id)
    file = SS::File.find(ss_file_id)
    importer = Article::Page::Importer.new(site, node, user)
    importer.import(file, task: task)
  ensure
    file.destroy rescue nil
  end

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond[:node_id] = node_id
    cond
  end
end
