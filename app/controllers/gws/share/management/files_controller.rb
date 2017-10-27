class Gws::Share::Management::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::FileFilter

  model Gws::Share::File
  before_action :set_item, only: [:show, :active]
  before_action :set_selected_items, only: [:destroy_all, :active_all]
  before_action :set_category
  before_action :set_folder
  before_action :set_folder_navi, only: [:index]

  private

  def set_crumbs
    set_folder
    if @folder.present?
      @crumbs << [t("mongoid.models.gws/share"), gws_share_files_path]
      @crumbs << [t("mongoid.models.gws/share/management"), gws_share_management_files_path]
      @crumbs << [@folder.name, action: :index]
    else
      @crumbs << [t("mongoid.models.gws/share"), gws_share_files_path]
      @crumbs << [t("mongoid.models.gws/share/management"), gws_share_management_files_path]
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
      deleted.
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def show
    raise "403" unless @item.readable?(@cur_user)
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

  def active
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_destroy @item.active
  end

  def active_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:edit, @cur_user, site: @cur_site)
        next if item.active
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

end
