class Cms::GenerationReport::TitlesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/generation_report/main/navi"

  model Cms::GenerationReport::Title

  helper_method :latest_task

  private

  def set_items
    @items ||= begin
      items = @model.site(@cur_site)
      items = items.where(generation_type: params[:type])
      items = items.allow(:read, @cur_user, site: @cur_site)
      items.order(created: -1)
    end
  end

  def latest_task
    @latest_task ||= begin
      criteria = Cms::Task.all
      criteria = criteria.site(@cur_site)
      case params[:type].to_s
      when "pages"
        task_name = Cms::Page::GenerateJob.task_name
      else
        task_name = Cms::Node::GenerateJob.task_name
      end
      criteria = criteria.where(name: task_name, node_id: nil)
      criteria = criteria.reorder(updated: -1)
      criteria.first
    end
  end

  def latest_title
    @latest_title ||= begin
      criteria = Cms::GenerationReport::Title.all
      criteria = criteria.site(@cur_site)
      criteria = criteria.where(generation_type: params[:type])
      criteria = criteria.where(sha256_hash: Cms::GenerationReport.sha256_hash(latest_task.perf_log_file_path))
      criteria.first
    end
  end

  public

  def new
    if latest_task.blank? || !::File.exist?(latest_task.perf_log_file_path) || ::File.size(latest_task.perf_log_file_path).zero?
      notice = t("mongoid.errors.models.cms/generation_report/title.generate_#{params[:type]}_is_not_done")
      redirect_to url_for(action: :index), notice: notice
      return
    end
    if latest_title.present?
      notice = t("mongoid.errors.models.cms/generation_report/title.latest_report_is_already_existed")
      redirect_to url_for(action: :index), notice: notice
      return
    end

    render
  end

  def create
    if latest_task.blank? || !::File.exist?(latest_task.perf_log_file_path) || ::File.size(latest_task.perf_log_file_path).zero?
      notice = t("mongoid.errors.models.cms/generation_report/title.generate_#{params[:type]}_is_not_done")
      redirect_to url_for(action: :index), notice: notice
      return
    end
    if latest_title.present?
      notice = t("mongoid.errors.models.cms/generation_report/title.latest_report_is_already_existed")
      redirect_to url_for(action: :index), notice: notice
      return
    end

    job_class = Cms::GenerationReportCreateJob.bind(site_id: @cur_site.id, user_id: @cur_user.id)
    job_class.perform_later(latest_task.id)

    redirect_to url_for(action: :index), notice: t("cms.notices.generation_report_jos_is_started")
  end
end
