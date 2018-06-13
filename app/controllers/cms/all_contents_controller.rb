class Cms::AllContentsController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/main/navi"

  def download
    return if request.get?
    job = Cms::ContentExportJob.new
    job.task = mock_task(
      site_id: @cur_site.id
    )
    job.perform
    send_file "#{Rails.root}/private/export/content-#{@cur_site.host}.zip"
  end

  def import
    @item = Cms::Task.find_or_create_by name: 'cms:import_content', site_id: @cur_site.id
    return if request.get?

    begin
      file = params[:item].try(:[], :file)
      if file.nil? || ::File.extname(file.original_filename) != ".zip"
        raise I18n.t("errors.messages.invalid_zip")
      end

      import_dir = "#{Rails.root}/private/import/"
      FileUtils.rm_rf(import_dir)
      FileUtils.mkdir_p(import_dir)
      File.open("#{import_dir}#{file.original_filename}", 'w+b') do |fp|
        fp.write file.read
      end

      # call job
      Cms::ContentImportJob.bind(site_id: @cur_site).perform_later(file: file.original_filename)
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
end
