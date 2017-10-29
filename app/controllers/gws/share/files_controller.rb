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
      @crumbs << [t("mongoid.models.gws/share"), gws_share_files_path]
      @crumbs << [@folder.name, action: :index]
    else
      @crumbs << [t("mongoid.models.gws/share"), action: :index]
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
    @folder_navi = Gws::Share::Folder.site(@cur_site).
        readable(@cur_user, @cur_site)
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    p = super
    p[:readable_member_ids] = [@cur_user.id]
    @skip_default_group = true
    if @category.present?
      p[:category_ids] = [ @category.id ]
    end
    p
  end

  public

  def index
    if @category.present? || @folder.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name if @category.present?
      params[:s][:folder] = @folder.id if @folder.present?
    end

    @items = @model.site(@cur_site).
      readable(@cur_user, @cur_site).
      active.
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def show
    raise "403" unless @item.readable?(@cur_user)
    render
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

  def delete
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable
  end

  def download_all
    download_root_dir = "/tmp/shirasagi_download"
    download_dir = "#{download_root_dir}" + "/" + "#{@cur_user.id}_#{SecureRandom.hex(4)}"

    Dir.glob("#{download_root_dir}" + "/" + "#{@cur_user.id}_*").each do |tmp_dir|
      FileUtils.rm_rf(tmp_dir) if File.exists?(tmp_dir)
    end

    FileUtils.mkdir_p(download_dir) unless FileTest.exist?(download_dir)

    filenames = []
    @items.each {|item| filenames.push(item.name)}
    filename_duplicate_flag = filenames.size == filenames.uniq.size ? 0 : 1

    @items.each do |item|
      if  filename_duplicate_flag == 0
        FileUtils.copy("#{item.path}", "#{download_dir}" + "/" + "#{item.name}") if File.exist?(item.path)
      elsif filename_duplicate_flag == 1
        FileUtils.copy("#{item.path}", "#{download_dir}" + "/" + item._id.to_s + "_" + "#{item.name}") if File.exist?(item.path)
      end
    end

    zipfile = download_dir + "/" + Time.now.strftime("%Y-%m-%d_%H-%M-%S") + ".zip"

    Zip::File.open(zipfile, Zip::File::CREATE) do |zip_file|
      Dir.glob("#{download_dir}/*").each do |downloadfile|
        zip_file.add(NKF::nkf('-sx --cp932',File.basename(downloadfile)), downloadfile)
      end
    end

    send_file(zipfile, type: 'application/zip', filename: File.basename(zipfile), disposition: 'attachment')

  end
end
