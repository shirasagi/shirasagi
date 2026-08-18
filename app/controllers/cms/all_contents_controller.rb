class Cms::AllContentsController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/main/navi"

  before_action :check_permission
  before_action :set_task, only: [:import]

  private

  def check_permission
    raise '403' unless @cur_user.cms_role_permit_any?(@cur_site, :use_cms_all_contents)
  end

  def set_crumbs
    @crumbs << [t("cms.all_contents"), cms_all_contents_path]
    case params[:action]
    when 'download_all'
      @crumbs << [t("cms.all_content.download_tab"), cms_all_contents_download_path]
    when 'import'
      @crumbs << [t("cms.all_content.import_tab"), cms_all_contents_import_path]
    when 'sampling_all'
      @crumbs << [t("cms.all_content.sampling_tab"), cms_all_contents_sampling_path]
    end
  end

  def set_task
    job_class = Cms::AllContentsImportJob
    @task = job_class.task_class.find_or_create_by(site_id: @cur_site.id, name: job_class.task_name)
  end

  public

  def download_all
    @item = Cms::AllContentParam.new(cur_site: @cur_site, cur_user: @cur_user)
    if request.get? || request.head?
      render
      return
    end

    @item.attributes = params.require(:item).permit(:encoding, :truncate)
    if @item.invalid?
      render
      return
    end

    task = Cms::FileGenTask.new(cur_site: @cur_site, cur_user: @cur_user)
    task.name = "all_contents_download_#{@cur_user.id}_#{Time.zone.now.to_i}"
    task.file_basename = "all_contents"
    task.file_format = "csv"
    task.params = @item.attributes.as_json
    task.save!

    job_class = Cms::AllContentsExportJob.bind(site_id: @cur_site, user_id: @cur_user, task_id: task)
    job_class.perform_later

    @task = task
    render
  end

  def import
    if request.get? || request.head?
      render
      return
    end

    safe_params = params.require(:item).permit(:in_file, :keep_timestamp)
    file = safe_params[:in_file]
    if file.blank? || ::File.extname(file.original_filename).casecmp(".csv") != 0
      @errors = [ t("errors.messages.invalid_csv") ]
      render({ action: :import })
      return
    end

    if !Cms::AllContentsImporter.valid_csv?(file)
      @errors = [ t("errors.messages.malformed_csv") ]
      render({ action: :import })
      return
    end

    if !@task.ready
      @errors = [ t('ss.notice.already_job_started') ]
      render({ action: :import })
      return
    end

    temp_file = SS::TempFile.new
    temp_file.in_file = file
    temp_file.save!

    job = Cms::AllContentsImportJob.bind(site_id: @cur_site, user_id: @cur_user)
    job.perform_later(temp_file.id, keep_timestamp: safe_params[:keep_timestamp] == "keep")
    redirect_to({ action: :import }, { notice: t('ss.notice.started_import') })
  end

  def sampling_all
    respond_to do |format|
      format.html
      format.csv do
        exporter = Cms::AllContentSampling.new(site: @cur_site)
        enumerable = exporter.enum_csv(encoding: "UTF-8")

        filename = "all_contents_sampling_#{Time.zone.now.to_i}.csv"

        response.status = 200
        send_enum enumerable, type: enumerable.content_type, filename: filename
      end
    end
  end
end
