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
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

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

      if @item.try(:thumb)
        return send_file @item.thumb.path, type: @item.content_type, filename: @item.filename, disposition: :inline
      end

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
        send_file @item.path, type: @item.content_type, filename: @item.download_filename,
          disposition: :attachment, x_sendfile: true
      else
        send_data @item.read, type: @item.content_type, filename: @item.download_filename,
          disposition: :attachment
      end
    end

    def resize
      set_item
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

      return if request.get?

      resizer = SS::ImageResizer.new get_params
      render_update resizer.resize(@item), { file: :resize }
    end
end
