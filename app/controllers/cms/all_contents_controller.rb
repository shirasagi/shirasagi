class Cms::AllContentsController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/main/navi"

  before_action :set_task, only: [:import]

  private

  def set_crumbs
    @crumbs << [t("cms.all_contents"), cms_all_contents_path]
    case params[:action]
    when 'download_all'
      @crumbs << [t("cms.all_content.download_tab"), cms_all_contents_download_path]
    when 'import'
      @crumbs << [t("cms.all_content.import_tab"), cms_all_contents_import_path]
    end
  end

  def set_task
    job_class = Cms::AllContentsImportJob
    @task = job_class.task_class.find_or_create_by(site_id: @cur_site.id, name: job_class.task_name)
  end

  public

  def download_all
    respond_to do |format|
      format.html
      format.csv do
        response.status = 200
        send_enum Cms::AllContent.enum_csv(@cur_site),
                  type: 'text/csv; charset=Shift_JIS',
                  filename: "all_contents_#{Time.zone.now.to_i}.csv"
      end
    end
  end

  def import
    if request.get?
      render
      return
    end

    safe_params = params.require(:item).permit(:in_file)
    file = safe_params[:in_file]
    if file.blank? || ::File.extname(file.original_filename).casecmp(".csv") != 0
      @errors = [ t("errors.messages.invalid_csv") ]
      render({ action: :import })
      return
    end

    if !Cms::AllContent.valid_header?(file)
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
    job.perform_later(temp_file.id)
    redirect_to({ action: :import }, { notice: t('ss.notice.started_import') })
  end
end
