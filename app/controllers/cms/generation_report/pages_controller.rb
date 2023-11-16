class Cms::GenerationReport::PagesController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/generation_report/main/navi"

  def index
    task = Cms::Task.all.site(@cur_site).where(name: Cms::Page::GenerateJob.task_name, node_id: nil).first
    unless task
      render
      return
    end
    if !::File.exist?(task.perf_log_file_path) || ::File.size(task.perf_log_file_path).zero?
      render
      return
    end

    redirect_to cms_generation_report_titles_path(type: "pages", task: task)
  end
end
