class Cms::Apis::LargeFileUploadController < ApplicationController
  include Cms::ApiFilter

  def init_files
    filenames = params.permit(filenames: [])[:filenames]

    set_task
    @task.prepare!(filenames)

    render json: { files: @task.acceptable_files, excluded_files: @task.excluded_files }
  end

  def create
    set_task
    filename = params.permit(:filename)[:filename]
    filename = File.basename(filename)

    blob = params.permit(:blob)[:blob]

    @task.append_blob!(filename, blob)

    render json: {}
  end

  def finalize
    set_task
    @task.execute!(@cur_user)
    render json: {}
  end

  private

  def set_task
    @task = Cms::LargeFileUploadTask.find_or_create_by(name: task_name, site_id: @cur_site.id)
  end

  def task_name
    "cms:large_file_task"
  end
end
