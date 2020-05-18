class Cms::MicheckerTask
  include SS::Model::Task

  TASK_NAME = "cms:michecker".freeze

  field :michecker_last_job_id, type: String
  field :michecker_last_result, type: Integer
  field :michecker_executed_at, type: DateTime

  class << self
    def tasks
      where(name: TASK_NAME)
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
    "#{SS::File.root}/ss_tasks/" + id.to_s.split(//).join("/") + "/_"
  end
end
