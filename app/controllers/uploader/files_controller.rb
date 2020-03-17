class Uploader::FilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Uploader::File

  before_action :set_format
  before_action :create_folder
  before_action :redirect_from_index
  before_action :set_item

  navi_view "uploader/main/navi"

  private

  def set_format
    request.formats = [params[:format] || :html]
  end

  def create_folder
    return if @model.file(@cur_node.path)
    cur_folder = @model.new path: @cur_node.path, is_dir: true
    cur_folder.site = @cur_site
    raise "404" unless cur_folder.save
  end

  def redirect_from_index
    return unless params[:filename].blank?
    redirect_to action: :file, filename: @cur_node.filename
  end

  def set_item
    filename = ::CGI.unescape params[:filename]
    path = ::File.expand_path(filename, @cur_site.path)

    if !(path == @cur_node.path || path.start_with?("#{@cur_node.path}/"))
      raise "404"
    end

    @item = @model.file path
    raise "404" unless @item

    @item.site = @cur_site
    @item.read if @item.text?
  end

  def set_items(path)
    @items = @model.search(path, params[:s]).sort_by
    dirs  = @items.select{ |item| item.directory?  }.sort_by { |item| item.name.capitalize }
    files = @items.select{ |item| !item.directory? }.sort_by { |item| item.name.capitalize }
    @items = dirs + files
    @items.each { |item| item.site = @cur_site }
  end

  def create_files
    @files.each do |file|
      next unless file.present?
      path = ::File.join(@cur_site.path, @item.filename, file.original_filename)
      item = @model.new(path: path, binary: file.read, site: @cur_site)

      if !item.save
        item.errors.each do |n, e|
          if n == :base
            attr = nil
          else
            attr = @model.t(n)
          end
          @item.errors.add :base, "#{item.name} - #{attr}#{e}"
        end
      end
    end
    location = "#{uploader_files_path}/#{@item.filename}"
    render_create @item.errors.empty?, location: location, render: { file: :new_files }
  end

  def create_directory
    path = "#{@item.path}/#{@directory}"
    item = @model.new(path: path, is_dir: true, site: @cur_site)

    if !item.save
      item.errors.each do |n, e|
        @item.errors.add :path, e
      end
    end
    location = "#{uploader_files_path}/#{@item.filename}"
    render_create @item.errors.empty?, location: location, render: { file: :new_directory }
  end

  def set_params(*keys)
    keys.each { |key| instance_variable_set("@#{key}", params[:item].try(:[], key)) }
  rescue => e
    Rails.logger.debug("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    raise "400"
  end

  public

  def file
    raise "404" unless @item
    action = %w(index new_directory new_files show edit delete check).delete(params[:do].presence || "index")
    raise "404" if action.blank?
    send action
  end

  def index
    raise "404" unless @item.directory?
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
    set_items(@item.path)
    render :index
  end

  def edit
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    render :edit
  end

  def show
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
    render :show
  end

  def delete
    raise "403" unless @cur_node.allowed?(:delete, @cur_user, site: @cur_site)
    render :delete
  end

  def new_files
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    render :new_files
  end

  def new_directory
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    render :new_directory
  end

  def create
    set_params(:directory, :files)
    if @directory
      create_directory
    elsif @files
      create_files
    else
      @item.errors.add :base, :set_filename
      if @directory
        render_create false, location: location, render: { file: :new_directory }
      else
        render_create false, location: location, render: { file: :new_files }
      end
    end
  end

  def update
    set_params(:filename, :files, :text, :file)
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    raise "400" unless @filename

    if !@item.directory?
      @text ? (@item.text = @text) : @item.read
    end
    ext = @item.ext
    filename = @item.filename
    @item.filename = @filename if @filename && @filename.start_with?(@cur_node.filename)
    @item.site = @cur_site
    if ext != @item.ext
      @item.errors.add :base, "#{filename}#{I18n.t("errors.messages.invalid_file_type")}"
      @item.filename = filename
      render_update false
      return
    end
    result = @item.save
    @item.path = @item.saved_path unless result

    file = @files.find(&:present?) rescue nil
    file = @file if @file.present?
    if result && file
      if File.extname(file.original_filename) != @item.ext
        @item.errors.add :base, "#{file.original_filename}#{I18n.t("errors.messages.invalid_file_type")}"
        result = false
      else
        binary = file.read
        binary = Uploader::File.remove_exif(binary) if file.content_type.start_with?('image/')
        Fs.binwrite @item.saved_path, binary
      end
    end

    location = "#{uploader_files_path}/#{@item.filename}?do=edit"
    render_update result, location: location
  end

  def destroy
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)

    if params[:ids].present?
      destroy_all
    else
      render_destroy @item.destroy, location: "#{uploader_files_path}/#{@item.dirname}"
    end
  end

  def destroy_all
    @paths = params[:ids]
    @paths.each do |path|
      item = @model.file("#{@item.path}/#{path}")
      item.destroy
    end
    render_destroy true, location: "#{uploader_files_path}/#{@item.filename}"
  end

  def check
    message = ''
    item_files = params[:item_files]
    original_filename = item_files.split('\\').last
    path = ::File.join(@cur_site.path, @item.filename, original_filename)
    extname = File.extname(original_filename)
    if extname != @item.ext && @item.ext.present?
      message += "#{I18n.t('uploader.notice.invalid_ext')}\n"
    end
    if File.exists?(path) && @item.directory?
      message += "#{I18n.t('uploader.notice.overwrite')}\n"
    end
    render json: { message: message }
  end
end
