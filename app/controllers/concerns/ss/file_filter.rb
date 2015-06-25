module SS::FileFilter
  extend ActiveSupport::Concern

  private
    def append_view_paths
      append_view_path "app/views/ss/crud/files"
      super
    end

    def set_last_modified
      response.headers["Last-Modified"] = CGI::rfc1123_date(@item.updated.in_time_zone)
    end

  public
    def create
      @item = @model.new get_params

      if @item.in_files
        render_create @item.save_files, location: { action: :index }
      else
        render_create @item.save
      end
    end

    def view
      set_item
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
      set_item
      set_last_modified

      require 'rmagick'
      image = Magick::Image.from_blob(@item.read).shift
      image = image.resize_to_fit 120, 90 if image.columns > 120 || image.rows > 90

      send_data image.to_blob, type: @item.content_type, filename: @item.filename, disposition: :inline
    rescue
      raise "500"
    end

    def download
      set_item
      set_last_modified

      if Fs.mode == :file && Fs.file?(@item.path)
        send_file @item.path, type: @item.content_type, filename: @item.filename,
          disposition: :attachment, x_sendfile: true
      else
        send_data @item.read, type: @item.content_type, filename: @item.filename,
          disposition: :attachment
      end
    end
end
