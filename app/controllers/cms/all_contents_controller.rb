class Cms::AllContentsController < ApplicationController
  include Cms::BaseFilter
  include SS::JobFilter

  navi_view "cms/main/navi"

  def download
    file = "#{Rails.root}/private/export/content-#{@cur_site.host}.zip"
    redirect_to({ action: :index }) unless FileTest.exist?(file)
    return if request.get?
    send_file file
  end

  def import
    @item = Cms::Task.find_or_create_by name: 'cms:import_content', site_id: @cur_site.id
    return if request.get?

    begin
      file = params[:item].try(:[], :file)
      if file.nil? || ::File.extname(file.original_filename) != ".zip"
        raise I18n.t("errors.messages.invalid_zip")
      end

      import_dir = "#{Rails.root}/private/import"
      import_zip = "#{import_dir}/content-#{@cur_site.host}.zip"
      FileUtils.rm(import_zip) if FileTest.exists?(import_zip)
      FileUtils.mkdir_p(import_dir)
      FileUtils.cp(file.path, import_zip)

      # call job
      Cms::ContentImportJob.bind(site_id: @cur_site).perform_later(file: "content-#{@cur_site.host}.zip")
      flash.now[:notice] = I18n.t("ss.notice.started_import")
    rescue => e
      @item.errors.add :base, e.to_s
    end
  end

  private

  def mock_task(attr)
    task = OpenStruct.new(attr)
    def task.log(msg)
      puts(msg)
    end
    task
  end

  def job_class
    Cms::ContentExportJob
  end

  def job_bindings
    {
      site_id: @cur_site.id,
    }
  end

  def task_name
    job_class.task_name
  end

  def set_item
    @item = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: nil
  end
end
