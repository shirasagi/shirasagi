class Sns::DownloadJobFilesController < ApplicationController
  include Sns::BaseFilter

  model SS::DownloadJobFile

  before_action :set_item

  private

  def set_item
    @item = @model.find(@cur_user, params[:filename])
    raise "404" unless @item
  end

  public

  def index
    send_file @item.path, type: @item.content_type, filename: @item.filename,
      disposition: "attachment", x_sendfile: true
  end
end
