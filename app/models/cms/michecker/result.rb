class Cms::Michecker::Result
  include SS::Model::Task

  TASK_NAME = "cms:michecker".freeze

  store_in collection: "cms_michecker_results"
  store_in_repl_master

  field :target_type, type: String
  field :target_id, type: String
  field :target_class, type: String
  field :michecker_last_job_id, type: String
  field :michecker_last_result, type: Integer
  field :michecker_last_executed_at, type: DateTime

  after_destroy :remove_all

  class << self
    def and_node(node)
      all.where(target_type: "node", target_class: node.class.name, target_id: node.id)
    end

    def and_page(page)
      all.where(target_type: "page", target_class: page.class.name, target_id: page.id)
    end
  end

  def html_checker_report_filepath
    "#{root_filepath}/hc_report.json"
  end

  def low_vision_report_filepath
    "#{root_filepath}/lv_report.json"
  end

  def low_vision_source_filepath
    "#{root_filepath}/lv_source.jpeg"
  end

  def low_vision_result_filepath
    "#{root_filepath}/lv_result.jpeg"
  end

  private

  def root_filepath
    "#{SS::File.root}/cms_michecker_results/" + id.to_s.split(//).join("/") + "/_"
  end

  def remove_all
    path = root_filepath
    ::Fs.rm_rf(path) if ::Fs.exists?(path)
  end
end
