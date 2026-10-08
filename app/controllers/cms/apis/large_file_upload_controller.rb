class Cms::Apis::LargeFileUploadController < ApplicationController
  include Cms::ApiFilter

  def init_files
    safe_params = params.require(:item).permit(files: [:file_id, :filename, :size])
    prepare_params = safe_params[:files].map do |param|
      Cms::LargeFileUploadTask::PrepareParam.new(**param)
    end

    set_task
    @task.prepare!(prepare_params)

    render json: { files: @task.acceptable_files.try(:map) { _1.slice("file_id", "filename") } || SS::EMPTY_ARRAY }
  end

  def create
    set_task
    safe_params = params.require(:item).permit(:file_id, :blob, :part_no)
    file_id = safe_params[:file_id].to_s
    if file_id.blank?
      head :bad_request
      return
    end

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

    @task.append_blob!(file_id, blob, part_no)

    head :ok
  end

  def finalize
    set_task
    @task.execute!(@cur_user)
    render json: { files: @task.acceptable_files.try(:map) { _1.slice("file_id", "filename") } || SS::EMPTY_ARRAY }
  end

  private

  def set_task
    @task ||= Cms::LargeFileUploadTask.find_or_create_by(name: task_name, site_id: @cur_site.id, user_id: @cur_user.id)
  end

  def task_name
    "cms:large_file_task:#{@cur_user.id}"
  end
end
