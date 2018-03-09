class Gws::Share::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::FileFilter

  model Gws::Share::File
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :delete, :lock, :unlock, :disable]
  before_action :set_selected_items, only: [:disable_all, :download_all]
  before_action :set_category
  before_action :set_folder
  before_action :set_tree_navi, only: [:index]
  after_action :update_folder_file_info, only: [:create, :update]

  navi_view "gws/share/main/navi"

  private

  def set_crumbs
    set_folder
    @crumbs << [@cur_site.menu_share_label || t("mongoid.models.gws/share"), gws_share_files_path]
    if @folder.present?
      folder_hierarchy_count = @folder.name.split("/").count - 1
      0.upto(folder_hierarchy_count) do |i|
        item_name = @folder.name.split("/")[0, i+1].join("/")
        item_path = gws_share_folder_files_path(folder: Gws::Share::Folder.site(@cur_site).find_by(name: item_name).id)
        @crumbs << [@folder.name.split("/")[i], item_path]
      end
    end
  end

  def set_category
    @categories = Gws::Share::Category.site(@cur_site).readable(@cur_user, site: @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Share::Category.site(@cur_site).readable(@cur_user, site: @cur_site).where(id: category_id).first
    end
  end

  def set_folder
    return if params[:folder].blank?
    @folder ||= Gws::Share::Folder.site(@cur_site).find(params[:folder])
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    p = super
    p[:readable_member_ids] = [@cur_user.id]
    p[:folder_id] = params[:folder] if params[:folder]
    @skip_default_group = true
    p[:category_ids] = [ @category.id ] if @category.present?
    p
  end

  def update_folder_file_info
    @folder.update_folder_descendants_file_info if @folder
    @item.folder.update_folder_descendants_file_info if @item.folder != @folder
  end

  public

  def index
    set_folder
    if params[:folder].present?
      raise "404" unless @folder.readable?(@cur_user)
    end

    if @category.present? || @folder.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name if @category.present?
      params[:s][:folder] = @folder.id if @folder.present?
    end

    @sort = params.dig(:s, :sort) || @cur_site.share_default_sort || 'filename'

    @items = @model.site(@cur_site).
      readable(@cur_user, site: @cur_site).
      active.search(params[:s]).
      custom_order(@sort).
      page(params[:page]).per(50)

    folder_name = Gws::Share::Folder.site(@cur_site).
        where(id: params[:folder].to_i).pluck(:name).first

    @sub_folders = Gws::Share::Folder.site(@cur_site).readable(@cur_user, site: @cur_site).
        sub_folder(params[:folder] || 'root_folder', folder_name)
  end

  def show
    raise "404" unless @item.readable?(@cur_user)
    if params[:folder].present?
      raise "404" unless @item.folder_id.to_s == params[:folder]
    end
    render
  end

  def new
    return redirect_to(action: :index) unless @folder
    @item = @model.new pre_params.merge(fix_params)
    raise "403" unless @item.allowed?(:write, @cur_user, site: @cur_site) && @folder.uploadable?(@cur_user)
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
      location = { action: :show, folder: @item.folder_id } if params[:action] == "update" && before_folder_id != @item.folder_id
      render_update @item.update, { location: location }
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
        format.json { render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked }
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
        format.json { render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked }
      end
    end
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    notice = t("ss.notice.deleted")
    location = gws_share_folder_files_path(folder: @item.folder_id)
    render_destroy @item.disable, { location: location, notice: notice }
  end

  def download_all
    zip = Gws::Share::Compressor.new(@cur_user, items: @items)
    zip.url = sns_download_job_files_url(user: zip.user, filename: zip.filename)

    if zip.deley_download?
      job = Gws::Share::CompressJob.bind(site_id: @cur_site, user_id: @cur_user)
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
