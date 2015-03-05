class Opendata::AppscriptsController < ApplicationController

  before_action :setfile

  private
    def setfile
      item = Opendata::App.find(params[:app])

      filename = params[:filename] + "." + params[:format]
      @appfile = item.appfiles.where(filename: filename).first
    end

  public
    def index
      if @appfile.present?
        send_file @appfile.file.path, type: @appfile.content_type, filename: @appfile.filename,
          disposition: :inline, x_sendfile: true
      end
    end

    def text
      if @appfile.present?
        send_file @appfile.file.path, :type => "text/plain", filename: @appfile.filename,
          disposition: :inline, x_sendfile: true
      end
    end
end
