class Gws::Share::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::FileFilter

  model Gws::Share::File
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :delete, :lock, :unlock, :disable]
  before_action :set_selected_items, only: [:disable_all, :download_all]
  before_action :set_category
  before_action :set_folder
  before_action :set_folder_navi, only: [:index]

  private

  def set_crumbs
    set_folder
    if @folder.present?
      @crumbs << [@cur_site.menu_share_label || t("mongoid.models.gws/share"), gws_share_files_path]
      folder_hierarchy_count = @folder.name.split("/").count - 1
      0.upto(folder_hierarchy_count) do |i|
        folder_name = @folder.name.split("/")[i]
        item_name = @folder.name.split("/")[0, i+1].join("/")
        item_id = Gws::Share::Folder.site(@cur_site).find_by(name: item_name).id
        item_path = gws_share_folder_files_path(folder: item_id)
        @crumbs << [folder_name, item_path]
      end
    else
      @crumbs << [@cur_site.menu_share_label || t("mongoid.models.gws/share"), action: :index]
    end
  end

  def set_category
    @categories = Gws::Share::Category.site(@cur_site).readable(@cur_user, @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Share::Category.site(@cur_site).where(id: category_id).first
    end
  end

  def set_folder
    return if params[:folder].blank?
    @folder ||= Gws::Share::Folder.site(@cur_site).find(params[:folder])
  end

  def set_folder_navi
    if @cur_user.gws_role_permissions["read_other_gws_share_folders_#{@cur_site.id}"]
      @folder_navi = Gws::Share::Folder.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site)
    elsif @cur_user.gws_role_permissions["read_private_gws_share_folders_#{@cur_site.id}"]
      @folder_navi = Gws::Share::Folder.site(@cur_site).
        readable(@cur_user, site: @cur_site)
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    p = super
    p[:readable_member_ids] = [@cur_user.id]
    p[:folder_id] = params[:folder] if params[:folder]
    @skip_default_group = true
    if @category.present?
      p[:category_ids] = [ @category.id ]
    end
    p
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

    @items = @model.site(@cur_site).
      readable(@cur_user, @cur_site).
      active.search(params[:s]).
      custom_order(params.dig(:s, :sort) || 'created_desc').
      page(params[:page]).per(50)

    @items.options[:sort].delete("_id")

    folder_name = Gws::Share::Folder.site(@cur_site).
        where(id: params[:folder].to_i).pluck(:name).first

    @sub_folders = Gws::Share::Folder.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        sub_folder(params[:folder] || 'root_folder', folder_name)
  end

  def show
    raise "404" unless @item.readable?(@cur_user)
    if params[:folder].present?
      raise "404" unless @item.folder_id.to_s == params[:folder]
    end
    render
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
      render_update @item.update, { before_folder_id: before_folder_id}
    end
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.is_a?(Gws::Addon::EditLock)
      unless @item.acquire_lock
        redirect_to action: :lock
        return
      end
    end
    render
  end

  def download_history
    set_item
    set_last_modified

    if params[:history_id].present?
      history_item = Gws::Share::History.where(item_id: @item.id, _id: params[:history_id]).first
      server_dir = File.dirname(@item.path)
      uploadfile_path = server_dir + "/#{@item.id}_#{history_item.uploadfile_srcname}"
    end

    if Fs.mode == :file && Fs.file?(uploadfile_path)
      send_file uploadfile_path, type: history_item.uploadfile_content_type, filename: history_item.uploadfile_name,
                disposition: :attachment, x_sendfile: true
    elsif Fs.mode == :file && Fs.file?(@item.path)
      send_file @item.path, type: @item.content_type, filename: @item.download_filename,
                disposition: :attachment, x_sendfile: true
    else
      send_data @item.read, type: @item.content_type, filename: @item.download_filename,
                disposition: :attachment
    end
  end

  def lock
    if @item.acquire_lock(force: params[:force].present?)
      render
    else
      respond_to do |format|
        format.html { render }
        format.json { render json: [ t("views.errors.locked", user: @item.lock_owner.long_name) ], status: :locked }
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
        format.html { render file: :show }
        format.json { render json: [ t("views.errors.locked", user: @item.lock_owner.long_name) ], status: :locked }
      end
    end
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable
  end

  def download_all
    zipfile = Time.zone.now.strftime("%Y-%m-%d_%H-%M-%S") + ".zip"
    tmp_dir_name = SecureRandom.hex(4).to_s

    filenames = []
    @items.each { |item| filenames.push(item.name) }
    filename_duplicate_flag = filenames.size == filenames.uniq.size ? 0 : 1

    @model.create_download_directory(@cur_user.id, @model.download_root_path, @model.zip_path(@cur_user.id, tmp_dir_name))
    @model.create_zip(@model.zip_path(@cur_user.id, tmp_dir_name), @items, filename_duplicate_flag)
    send_file(@model.zip_path(@cur_user.id, tmp_dir_name),
              type: 'application/zip',
              filename: zipfile,
              disposition: 'attachment',
              x_sendfile: true)
  end

  def render_update(result, opts = {})
    if params[:action] == "update" && opts[:before_folder_id] != @item.folder_id
      location = { action: :show,  folder: @item.folder_id}
    else
      location = opts[:location].presence || crud_redirect_url || { action: :show }
    end

    render_opts = opts[:render].presence || { file: :edit }
    notice = opts[:notice].presence || t("ss.notice.saved")

    if result
      respond_to do |format|
        format.html { redirect_to location, notice: notice }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render render_opts }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end

  def render_destroy_all(result)
    location = crud_redirect_url || { action: :index }
    if params[:action] == "disable_all" || params[:action] == "disable"
      notice = result ? { notice: t("gws/share.notice.disable") } : {}
    else
      notice = result ? { notice: t("ss.notice.deleted") } : {}
    end

    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    respond_to do |format|
      format.html { redirect_to location, notice }
      format.json { head json: errors }
    end
  end

  def render_destroy(result, opts = {})
    location = opts[:location].presence || crud_redirect_url || { action: :index }
    render_opts = opts[:render].presence || { file: :delete }
    if params[:action] == "disable"
      notice = opts[:notice].presence || t("gws/share.notice.disable")
    else
      notice = opts[:notice].presence || t("ss.notice.saved")
    end

    if result
      respond_to do |format|
        format.html { redirect_to location, notice: notice }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render render_opts }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end
end
