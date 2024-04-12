class Cms::AllContentsImportJob < Cms::ApplicationJob
  include Job::SS::TaskFilter
  include SS::ZipFileImport

  self.task_class = Cms::Task
  self.task_name = "cms:all_contents"

  def perform(*args)
    options = args.extract_options!
    options.symbolize_keys!
    ss_file_id = args.first

    file = SS::File.find(ss_file_id)
    importer = Cms::AllContentsImporter.new(site, node, user)
    importer.import(file, task: task, keep_timestamp: options[:keep_timestamp])
  ensure
    file.destroy rescue nil
  end
end
