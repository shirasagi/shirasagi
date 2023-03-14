class Uploader::FilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::SanitizerFilter

  model Uploader::File

  prepend_before_action :set_format
  before_action :create_folder
  before_action :redirect_from_index
  before_action :set_item
  before_action :set_item_was, if: ->{ @item }
  before_action :set_crumbs
  before_action :deny_sanitizing_file, only: [:update, :destroy]
  after_action :save_job, only: [:create, :update, :destroy, :destroy_all]

  helper_method :editable_with_upload_policy?

  navi_view "uploader/main/navi"

  private

  def set_format
    request.formats = [params[:format] || :html]
  end

  def set_crumbs
    filename = @item.filename.sub(@cur_node.filename, "")
    url = ::File.join(uploader_files_path, @cur_node.filename)

    filename.split("/").select(&:present?).each do |name|
      url = ::File.join(url, name)
      @crumbs << [name, url]
    end
    if %w(show edit delete check).include?(params[:do])
      # do=show などの場合、@crumbs の末尾にはファイル名が入っている。
      # pop することで、ぱんクズにファイル名を表示しないようにする。
      @crumbs.pop
    end
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
    Uploader::File.set_sanitizer_state([@item], { site_id: @cur_site.id })
  end

  def set_item_was
    @path_was = @item.path
    @text_was = @item.text if @item.text?
  end

  def save_job
    return unless SS::UploadPolicy.upload_policy == 'sanitizer'
    return unless response.headers['Location']

    job_file = Uploader::JobFile.new_job(site_id: @cur_site.id)
    action = params[:action]

    if action == 'create' && @directory
      job_file.bind_mkdir(["#{@item.path}/#{@directory}"]).save_job
    elsif action == 'create'
      @items.each do |item|
        job_file.upload(item.path)
      end
    elsif action == 'update'
      job_file.bind_mv(@path_was, @item.path) if @path_was != @item.path
      job_file.bind_text(@item.path, @item.text) if @text && @text_was != @item.text
      job_file.save_job
      job_file.upload(@item.path) if @file
    elsif action == 'destroy'
      paths = [@path_was]
      paths = @paths.map { |name| "#{@path_was}/#{name}" } if @paths
      job_file.bind_rm(paths).save_job
    end
  end

  def set_items(path)
    @items = @model.search(path, params[:s]).sort_by
    dirs  = @items.select{ |item| item.directory?  }.sort_by { |item| item.name.capitalize }
    files = @items.select{ |item| !item.directory? }.sort_by { |item| item.name.capitalize }
    @items = dirs + files
    @items.each { |item| item.site = @cur_site }
  end

  def create_files
    @items = []
    @files.each do |file|
      next unless file.present?
      path = ::File.join(@cur_site.path, @item.filename, file.original_filename)
      item = @model.new(path: path, binary: file.read, site: @cur_site)

      if item.save
        @items << item
      else
        SS::Model.copy_errors(item, @item, prefix: "#{item.name} - ")
      end
    end
    location = "#{uploader_files_path}/#{@item.filename}"
    render_create @item.errors.empty?, location: location, render: { template: "new_files" }
  end

  def create_directory
    path = "#{@item.path}/#{@directory}"
    item = @model.new(path: path, is_dir: true, site: @cur_site)

    if !item.save
      item.errors.each do |error|
        @item.errors.add :path, error.message
      end
    end
    location = "#{uploader_files_path}/#{@item.filename}"
    render_create @item.errors.empty?, location: location, render: { template: "new_directory" }
  end

  def set_params(*keys)
    keys.each { |key| instance_variable_set("@#{key}", params[:item].try(:[], key)) }
  rescue => e
    Rails.logger.debug("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    raise "400"
  end

  def editable_with_upload_policy?
    SS::UploadPolicy.upload_policy != "sanitizer" && SS::UploadPolicy.upload_policy != "restricted"
  end

  public

  def file
    raise "404" unless @item
    action = %w(index new_directory new_files show edit delete check).delete(params[:do].presence || "index")
    raise "404" if action.blank?
    send action
  end

  def index
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
    return redirect_to("#{request.path}?do=show") unless @item.directory?
    set_items(@item.path)
    Uploader::File.set_sanitizer_state(@items, { site_id: @cur_site.id })
    render :index
  end

  def edit
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)

    if editable_with_upload_policy?
      render :edit
    else
      @item.errors.add :base, :edit_restricted
      render :edit_restricted
    end
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
        render_create false, location: location, render: { template: "new_directory" }
      else
        render_create false, location: location, render: { template: "new_files" }
      end
    end
  end

  def update
    set_params(:filename, :files, :text, :file)
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    raise "403" unless editable_with_upload_policy?
    raise "400" unless @filename

    if !@item.directory?
      @text ? (@item.text = @text) : @item.read
    end
    ext = @item.ext
    filename = @item.filename
    @item.filename = @filename if @filename && @filename.start_with?(@cur_node.filename)
    @item.site = @cur_site
    if ext != @item.ext
      @item.errors.add :base, "#{@item.filename} #{I18n.t("errors.messages.invalid_file_type")}"
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
    # initialize items
    @selected_items = @model.search(@item.path, params[:s])
    @selected_items.each { |item| item.site = @cur_site }
    Uploader::File.set_sanitizer_state(@selected_items, { site_id: @cur_site.id })

    # check ids, path
    @selected_items = @selected_items.select do |item|
      params[:ids].include?(item.basename) && item.path.start_with?(@cur_node.path)
    end

    if params[:destroy_all].blank?
      render "cms/crud/destroy_all"
      return
    end

    @deleted_items, @undeleted_items = @selected_items.partition do |item|
      # deny_sanitizing_file
      next false if item.sanitizer_state == 'wait' #&& updated condition
      item.destroy
    end
    @paths = @deleted_items.map(&:filename)
    render_confirmed_all @undeleted_items.blank?, location: "#{uploader_files_path}/#{@item.filename}"
  end

  def render_confirmed_all(result, opts = {})
    location = opts[:location].presence || crud_redirect_url || { action: :index }
    if result
      notice = { notice: opts[:notice].presence || t("ss.notice.deleted") }
    else
      notice = { notice: t("ss.notice.unable_to_delete", items: @undeleted_items.map(&:basename).join("、")) }
    end
    errors = @selected_items.map { |item| [item.path, item.errors.full_messages] }

    respond_to do |format|
      format.html { redirect_to location, notice }
      format.json { head json: errors }
    end
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
    if File.exist?(path) && @item.directory?
      message += "#{I18n.t('uploader.notice.overwrite')}\n"
    end
    render json: { message: message }
  end
end
