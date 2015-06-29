class Fs::FilesController < ApplicationController
  include Fs::FileFilter

  before_action :set_item

  private
    def set_item
      id = params[:id_path].present? ? params[:id_path].gsub(/\//, "") : params[:id]
      path  = params[:filename]
      path << ".#{params[:format]}" if params[:format].present?

      @item = SS::File.find_by id: id, filename: path, state: "public"
    end

    def set_last_modified
      response.headers["Last-Modified"] = CGI::rfc1123_date(@item.updated.in_time_zone)
    end

  public
    def index
      set_last_modified

      if Fs.mode == :file && Fs.file?(@item.path)
        send_file @item.path, type: @item.content_type, filename: @item.filename,
          disposition: :inline, x_sendfile: true
      else
        send_data @item.read, type: @item.content_type, filename: @item.filename,
          disposition: :inline
      end
    end

    def thumb
      if @item.thumb
        @item = @item.thumb
        index
      else
        set_last_modified

        width  = params[:width]
        height = params[:height]
        send_thumb @item.read, type: @item.content_type, filename: @item.filename, disposition: :inline,
          width: width, height: height
      end
    rescue => e
      raise "500"
    end
end
