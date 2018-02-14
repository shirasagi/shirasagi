class Gws::Share::FoldersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Share::Folder

  navi_view "gws/share/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_share_label || t("modules.gws/share"), gws_share_files_path]
    @crumbs << [t("mongoid.models.gws/share/folder"), gws_share_folders_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    p = super
    p[:readable_member_ids] = [@cur_user.id]
    @skip_default_group = true
    p
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def update
    @item.attributes["before_folder_name"] = @item.name

    @item.attributes = get_params
    @item.attributes["controller"] = params["controller"]
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    @item.attributes["action"] = params[:action]
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update, { controller: params["controller"] }
  end

  def create
    @item = @model.new get_params
    @item.attributes["action"] = params["action"]
    parent_folder = @model.where(site_id: @cur_site.id, name: File.dirname(@item.name)).first

    if parent_folder.present?
      @item.readable_group_ids = (@item.readable_group_ids + parent_folder.readable_group_ids).uniq
      @item.readable_member_ids = (@item.readable_member_ids + parent_folder.readable_member_ids).uniq
      @item.group_ids = (@item.group_ids + parent_folder.group_ids).uniq
      @item.user_ids = (@item.user_ids + parent_folder.user_ids).uniq
    end

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_create @item.save
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
    if @item.name.include?("/")
      parent_share_max_file_size = @model.where(site_id: @cur_site.id, name: @item.name.split("/").first)
                                         .first.share_max_file_size
      parent_share_max_folder_size = @model.where(site_id: @cur_site.id, name: @item.name.split("/").first)
                                         .first.share_max_folder_size
      @item.share_max_file_size = parent_share_max_file_size
      @item.share_max_folder_size = parent_share_max_folder_size
    end
    render
  end

  def download_folder
    raise "403" unless @model.allowed?(:download, @cur_user, site: @cur_site)

    set_item
    @items = SS::File.where(folder_id: params[:id].to_i, deleted: nil)

    zip = Gws::Share::Compressor.new(@cur_user, items: @items, name: "#{@item.trailing_name}.zip")
    zip.url = sns_download_job_files_url(user: zip.user, filename: zip.filename, name: zip.name)

    if zip.deley_download?
      job = Gws::Share::CompressJob.bind(site_id: @cur_site, user_id: @cur_user)
      job.perform_later(zip.serialize)

      flash[:notice_options] = { timeout: 0 }
      redirect_to({ action: :show }, { notice: zip.delay_message })
    else
      raise '500' unless zip.save
      send_file(zip.path, type: zip.type, filename: zip.name, disposition: 'attachment', x_sendfile: true)
    end
  end
end
