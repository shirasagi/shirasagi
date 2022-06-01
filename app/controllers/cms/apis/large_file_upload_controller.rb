class Cms::Apis::LargeFileUploadController < ApplicationController
  include Cms::ApiFilter
  protect_from_forgery
  skip_before_action :verify_authenticity_token

  def init_files
    files = {}
    excluded_files = []
    filenames = params[:filenames]
    extensions = SS::MaxFileSize.all.map(&:extensions).flatten

    filenames.each do |filename|
      if !extensions.include?(File.extname(filename).sub(/\./, ""))
        excluded_files << filename
        next
      end

      file = Cms::File.create(site_id: @cur_site.id, name: filename, filename: filename, model: "cms/file")
      files["#{file.name}"] = file.id
    end

    respond_to do |format|
      format.json { render json: { files: files, cur_site_id: @cur_site.id, excluded_files: excluded_files } }
    end
  end

  def create
    set_task
    filename = params[:filename]
    tmp_file = "#{tmp_file_path}/#{filename}"
    binary = params[:blob].read

    Retriable.retriable do
      dirname = ::File.dirname(tmp_file)
      ::FileUtils.mkdir_p(dirname) unless ::Dir.exist?(dirname)
      File.open(tmp_file, "ab") do |f|
        f.write binary
      end
    end

    respond_to do |format|
      format.json { render json: {} }
    end
  end

  def finalize
    set_task
    @task.execute(params[:files], params[:cur_site_id])
    respond_to do |format|
      format.json { render json: {} }
    end
  end

  private

  def set_task
    @task = Cms::LargeFileUploadTask.find_or_create_by(name: task_name, site_id: @cur_site.id)
  end

  def task_name
    "cms:large_file_task"
  end

  def tmp_file_path
    "#{SS::File.root}/ss_tasks/#{@task.id.to_s.chars.join("/")}"
  end
end
