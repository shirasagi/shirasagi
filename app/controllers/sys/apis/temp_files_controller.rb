class Sys::Apis::TempFilesController < ApplicationController
  include SS::BaseFilter
  include SS::CrudFilter

  model SS::TempFile

  layout "ss/ajax"

  private

  def fix_params
    { cur_user: @cur_user }
  end

  def append_view_paths
    append_view_path "app/views/ss/crud/files"
    append_view_path "app/views/sys/apis/ajax_files"
    super
  end

  def set_last_modified
    response.headers["Last-Modified"] = CGI::rfc1123_date(@item.updated.in_time_zone)
  end

  def set_item
    super
    raise "404" unless @item.user_id == @cur_user.id
  end

  def select_with_clone
    set_item

    item = SS::TempFile.new

    @item.attributes.each do |key, val|
      next if key =~ /^(id|file_id)$/
      next if key =~ /^(group_ids|permission_level|category_ids)$/
      item.send("#{key}=", val) unless item.send(key)
    end

    item.in_file = @item.uploaded_file
    item.state   = "public"
    item.name    = @item.name
    item.save
    item.in_file.delete
    @item = item

    render file: :select, layout: !request.xhr?
  end

  public

  def index
    @items = @model
    @items = @items.site(@cur_site) if @cur_site
    @items = @items.allow(:read, @cur_user).
      order_by(filename: 1).
      page(params[:page]).per(20)
  end

  def select
    set_item
    render file: :select, layout: !request.xhr?
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if @item.in_files
      def @item.to_json
        saved_files.to_json
      end
      render_create @item.save_files, location: { action: :index }
    else
      render_create @item.save
    end
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if @item.in_file.blank? && @item.in_data_url.present?
      media_type, _, data = SS::DataUrl.decode(@item.in_data_url)
      raise '400' if @item.content_type != media_type

      tmp_file = Fs::UploadedFile.new('ss_file')
      tmp_file.original_filename = @item.filename
      tmp_file.content_type = @item.content_type
      tmp_file.binmode
      tmp_file.write(data)
      tmp_file.rewind

      begin
        @item.in_file = tmp_file
        render_update @item.update
      ensure
        tmp_file.close
      end
    else
      render_update @item.update
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
      if Fs.mode == :file && Fs.file?(@item.thumb.path)
        send_file @item.thumb.path, type: @item.thumb.content_type, filename: @item.thumb.filename,
          disposition: :inline, x_sendfile: true
      else
        send_data @item.thumb.read, type: @item.thumb.content_type, filename: @item.thumb.filename,
          disposition: :inline
      end
    else
      require 'rmagick'
      image = Magick::Image.from_blob(@item.read).shift
      image = image.resize_to_fit 120, 90 if image.columns > 120 || image.rows > 90

      send_data image.to_blob, type: @item.content_type, filename: @item.filename, disposition: :inline
    end
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
