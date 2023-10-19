class Cms::GenerationReport::TitlesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/main/navi"

  model Cms::GenerationReport::Title

  helper_method :task

  private

  def task
    @task ||= Cms::Task.site(@cur_site).find(params[:task])
  end

  def set_items
    @items ||= begin
      items = @model.site(@cur_site)
      items = items.where(task_id: task.id)
      items = items.allow(:read, @cur_user, site: @cur_site)
      items.order(created: -1)
    end
  end

  def latest_title
    @latest_title ||= begin
      criteria = Cms::GenerationReport::Title.all
      criteria = criteria.site(@cur_site)
      criteria = criteria.where(task_id: task.id)
      criteria = criteria.where(sha256_hash: Cms::GenerationReport.sha256_hash(task.perf_log_file_path))
      criteria.first
    end
  end

  public

  def new
    if latest_title.present?
      redirect_to url_for(action: :index), notice: "最新の書き出し性能レポートがすでに存在します。"
      return
    end

    render
  end

  def create
    if latest_title.present?
      redirect_to url_for(action: :index), notice: "最新の書き出し性能レポートがすでに存在します。"
      return
    end

    job_class = Cms::GenerationReportCreateJob.bind(site_id: @cur_site.id, user_id: @cur_user.id, task_id: task.id)
    job_class.perform_later

    redirect_to url_for(action: :index), notice: "書き出し性能レポート作成ジョブを実行しました。"
  end
end
