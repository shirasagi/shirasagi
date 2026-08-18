class Sns::Apis::FileGenTasksController < ApplicationController
  include Sns::BaseFilter

  model SS::FileGenTask

  private

  def set_item
    @item ||= @model.where(user_id: @cur_user).find(params[:id])
  end

  public

  def download
    set_item
    raise SS::NotFoundError if @item.state != @model::STATE_COMPLETED
    raise SS::NotFoundError unless File.exist?(@item.generated_file_path)
    raise SS::NotFoundError if File.size(@item.generated_file_path) <= 0

    type = SS::MimeType.find(@item.file_format)
    ss_send_file @item.generated_file_path, type: type, filename: @item.public_filename,
                 disposition: :attachment, x_sendfile: true  end
end
