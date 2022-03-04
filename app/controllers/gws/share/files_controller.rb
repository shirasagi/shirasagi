class Gws::Share::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::FileFilter

  model Gws::Share::File

  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :delete, :lock, :unlock, :disable]
  before_action :set_selected_items, only: [:disable_all, :download_all]
  before_action :set_categories, only: [:index]
  before_action :set_category
  before_action :set_folder
  before_action :set_tree_navi, only: [:index]
  before_action :set_default_readable_setting, only: [:new]

  after_action :update_folder_file_info, only: [:create, :update]

  navi_view "gws/share/main/navi"

  private

  def set_crumbs
    set_folder
    @crumbs << [@cur_site.menu_share_label || t("mongoid.models.gws/share"), gws_share_files_path(category: params[:category])]
    if @folder.present?
      folder_hierarchy_count = @folder.name.split("/").count - 1
      0.upto(folder_hierarchy_count) do |i|
        item_name = @folder.name.split("/")[0, i + 1].join("/")
        item_folder = Gws::Share::Folder.site(@cur_site).find_by(name: item_name)
        item_path = gws_share_folder_files_path(folder: item_folder.id, category: params[:category])
        @crumbs << [@folder.name.split("/")[i], item_path]
      end
    end
  end

  def set_categories
    @categories = Gws::Share::Category.site(@cur_site).readable(@cur_user, site: @cur_site).tree_sort
  end

  def set_category
    return if params[:category].blank?

    @category ||= Gws::Share::Category.site(@cur_site).where(id: params[:category]).first
    return unless @category

    raise '403' unless @category.readable?(@cur_user) || @category.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_folder
    return if params[:folder].blank?

    @folder ||= Gws::Share::Folder.site(@cur_site).find(params[:folder])
    raise "403" unless @folder.readable?(@cur_user) || @folder.allowed?(:read, @cur_user, site: @cur_site)
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_default_readable_setting
    @default_readable_setting = proc do
      @item.readable_setting_range = "select"
      @item.readable_group_ids = [ @cur_group.id ]
      @item.readable_member_ids = [ @cur_user.id ]
      @item.readable_custom_group_ids = []
    end
  end

  def pre_params
    p = super
    p[:folder_id] = params[:folder] if params[:folder]
    p[:category_ids] = [@category.id] if @category.present?
    p
  end

  def set_item
    super
    raise "404" unless @item.readable?(@cur_user) || @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  def update_folder_file_info
    @folder.update_folder_descendants_file_info if @folder
    @item.folder.update_folder_descendants_file_info if @item.is_a?(Gws::Share::File) && @item.folder != @folder
  end

  def render_update(result, opts = {})
    unless result
      # if result is false, browser goes to edit form which requires to be locked.
      unless @item.acquire_lock
        redirect_to action: :lock
        return
      end
    end

    super
  end

  public

  def index
    set_folder

    if @category.present? || @folder.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name if @category.present?
      params[:s][:folder] = @folder.id if @folder.present?
    end

    @sort = params.dig(:s, :sort) || @cur_site.share_default_sort || 'filename_asc'

    @items = @model.site(@cur_site).active

    if @model.other_permission?(:read, @cur_user, site: @cur_site)
      @items = @items.allow(:read, @cur_user, site: @cur_site)
    else
      @items = @items.readable(@cur_user, site: @cur_site)
    end

    @items = @items.
      search(params[:s]).
      custom_order(@sort).
      page(params[:page]).per(50)
  end

  def show
    if params[:folder].present?
      raise "404" unless @item.folder_id.to_s == params[:folder]
    end
    render
  end

  def new
    return redirect_to(action: :index) unless @folder
    raise "403" unless @model.allowed?(:write, @cur_user, site: @cur_site) && @folder.uploadable?(@cur_user)

    @model = Gws::Share::FileUploader
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    return redirect_to(action: :index) unless @folder
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site) && @folder.uploadable?(@cur_user)

    @model = Gws::Share::FileUploader
    @item = @model.new get_params
    @item.folder_id = params[:folder] if params[:folder]

    render_create @item.save_files, location: { action: :index }
  end

  def update
    before_folder_id = @item.folder_id
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
      if params[:action] == "update" && before_folder_id != @item.folder_id
        location = { action: :show, folder: @item.folder_id, category: params[:category] }
      end
      render_update @item.update, { location: location }
    end
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    unless @item.acquire_lock
      redirect_to action: :lock
      return
    end

    render
  end

  def download_history
    set_item
    set_last_modified

    raise "404" if params[:history_id].blank?

    history_item = @item.histories.where(id: params[:history_id].to_s).first
    raise "404" if history_item.blank?

    if history_item.id == @item.histories.first.id
      # latest history item
      path = @item.path
      type = @item.content_type
      filename = @item.download_filename
    else
      path = history_item.path
      type = history_item.uploadfile_content_type
      filename = history_item.uploadfile_name
    end

    raise "404" unless Fs.file?(path)

    ss_send_file path, type: type, filename: filename, disposition: :attachment
  end

  def lock
    if @item.acquire_lock(force: params[:force].present?)
      render
    else
      respond_to do |format|
        format.html { render }
        format.json { render json: [t("errors.messages.locked", user: @item.lock_owner.long_name)], status: :locked }
      end
    end
  end

  def unlock
    unless @item.locked?
      respond_to do |format|
        format.html { redirect_to(action: :edit) }
        format.json { head :no_content }
      end
      return
    end

    raise "403" if !@item.lock_owned? && !@item.allowed?(:unlock, @cur_user, site: @cur_site, node: @cur_node)

    unless @item.locked?
      respond_to do |format|
        format.html { redirect_to(action: :edit) }
        format.json { head :no_content }
      end
      return
    end

    if @item.release_lock(force: params[:force].present?)
      respond_to do |format|
        format.html { redirect_to(action: :edit) }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render template: "show" }
        format.json { render json: [t("errors.messages.locked", user: @item.lock_owner.long_name)], status: :locked }
      end
    end
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    location = { action: :index, folder: params[:folder], category: params[:category] }
    render_destroy @item.disable, { location: location }
  end

  def download_all
    zip = Gws::Compressor.new(@cur_user, items: @items)
    zip.url = sns_download_job_files_url(user: zip.user, filename: zip.filename)

    if zip.deley_download?
      job = Gws::CompressJob.bind(site_id: @cur_site, user_id: @cur_user)
      job.perform_later(zip.serialize)

      flash[:notice_options] = { timeout: 0 }
      redirect_to({ action: :index }, { notice: zip.delay_message })
    else
      raise '500' unless zip.save

      send_file(zip.path, type: zip.type, filename: zip.name, disposition: 'attachment', x_sendfile: true)
    end
  end

  def render_destroy_all(result)
    location = crud_redirect_url || { action: :index }
    notice = result ? { notice: t("ss.notice.deleted") } : {}

    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    respond_to do |format|
      format.html { redirect_to location, notice }
      format.json { head json: errors }
    end
  end
end
