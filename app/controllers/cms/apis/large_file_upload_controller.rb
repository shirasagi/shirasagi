class Cms::Apis::LargeFileUploadController < ApplicationController
  include Cms::ApiFilter

  def init_files
    filenames = params.permit(filenames: [])[:filenames]

    set_task
    @task.prepare!(filenames)

    render json: { files: @task.acceptable_files.map { _1["filename"] }, excluded_files: @task.excluded_files }
  end

  def create
    set_task
    safe_params = params.permit(:filename, :blob, :part_no)
    filename = safe_params[:filename]
    unless filename
      head :bad_request
      return
    end
    filename = filename.to_s

    blob = safe_params[:blob]
    unless blob
      head :bad_request
      return
    end

    part_no = safe_params[:part_no]
    unless part_no.numeric?
      head :bad_request
      return
    end
    part_no = part_no.to_i

    @task.append_blob!(filename, blob, part_no)

    render json: {}
  end

  def finalize
    set_task
    @task.execute!(@cur_user)
    render json: {}
  end

  private

  def set_task
    @task = Cms::LargeFileUploadTask.find_or_create_by(name: task_name, site_id: @cur_site.id, user_id: @cur_user.id)
  end

  def task_name
    "cms:large_file_task:#{@cur_user.id}"
  end
end
