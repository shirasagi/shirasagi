class Gws::Share::Management::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::FileFilter

  model Gws::Share::File
  navi_view "gws/share/main/navi"

  before_action :set_item, only: [:show, :active, :delete, :recover, :destroy]
  before_action :set_selected_items, only: [:destroy_all, :active_all]
  before_action :set_category
  before_action :set_folder
  before_action :set_tree_navi, only: [:index]
  after_action :update_folder_file_info, only: [:create, :update, :destroy]
  after_action :update_folder_file_infos, only: [:destroy_all]

  private

  def set_crumbs
    set_folder
    @crumbs << [@cur_site.menu_share_label || t("mongoid.models.gws/share"), gws_share_files_path(category: params[:category])]
    @crumbs << [t('ss.navi.trash'), gws_share_management_files_path(category: params[:category])]
    if @folder.present?
      folder_hierarchy_count = @folder.name.split("/").count - 1
      0.upto(folder_hierarchy_count) do |i|
        folder_name = @folder.name.split("/")[i]
        item_name = @folder.name.split("/")[0, i+1].join("/")
        item_id = Gws::Share::Folder.site(@cur_site).find_by(name: item_name).id
        item_path = gws_share_management_folder_files_path(folder: item_id, category: params[:category])
        @crumbs << [folder_name, item_path]
      end
    end
  end

  def set_category
    @categories = Gws::Share::Category.site(@cur_site).readable(@cur_user, site: @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Share::Category.site(@cur_site).where(id: category_id).first
    end
  end

  def set_folder
    return if params[:folder].blank?

    @folder ||= Gws::Share::Folder.site(@cur_site).find(params[:folder])
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  # def pre_params
  #   p = super
  #   if @category.present?
  #     p[:category_ids] = [ @category.id ]
  #   end
  #   p
  # end

  def set_item
    super
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  def update_folder_file_info
    @folder.update_folder_descendants_file_info if @folder
    @item.folder.update_folder_descendants_file_info if @item && @item.folder != @folder
  end

  def update_folder_file_infos
    return if @folder_ids.blank?

    Gws::Share::Folder.site(@cur_site).in(id: @folder_ids.uniq).each do |folder|
      folder.update_folder_descendants_file_info
    end
  end

  public

  def index
    if params[:folder].present?
      raise "403" unless @folder.allowed?(:read, @cur_user, site: @cur_site)
    end
    if @category.present? || @folder.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name if @category.present?
      params[:s][:folder] = @folder.id if @folder.present?
    end

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      deleted.
      search(params[:s]).
      custom_order(params.dig(:s, :sort) || 'updated_desc').
      page(params[:page]).per(50)
  end

  def show
    render
  end

  def recover
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)

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

  def active
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    location = { action: :index, folder: params[:folder], category: params[:category] }
    render_destroy @item.active, { location: location }
  end

  # def active_all
  #   entries = @items.entries
  #   @items = []
  #
  #   entries.each do |item|
  #     if item.allowed?(:edit, @cur_user, site: @cur_site)
  #       next if item.active
  #     else
  #       item.errors.add :base, :auth_error
  #     end
  #     @items << item
  #   end
  #   render_destroy_all(entries.size != @items.size)
  # end

  def destroy_all
    entries = @items.entries
    @items = []
    @folder_ids = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        if item.destroy
          @folder_ids << item.folder_id
          next
        end
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def render_destroy_all(result)
    location = crud_redirect_url || { action: :index }
    if params[:action] == "active_all"
      notice = result ? { notice: t("ss.notice.restored") } : {}
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
    render_opts = opts[:render].presence || { template: "delete" }
    if params[:action] == "active"
      notice = opts[:notice].presence || t("ss.notice.restored")
    elsif params[:action] == "destroy"
      notice = opts[:notice].presence || t("ss.notice.deleted")
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
