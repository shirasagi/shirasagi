class Gws::Share::FoldersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Share::Folder

  private

  def set_crumbs
    @crumbs << [t("modules.gws/share"), gws_share_files_path]
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
    @item.attributes = get_params
    @item.attributes["controller"] = params["controller"]
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update, { controller: params["controller"] }
  end

  def download_folder
    raise "403" unless @model.allowed?(:download, @cur_user, site: @cur_site)
    ss_file_items = SS::File.where(folder_id: params[:id].to_i, deleted: nil)

    filenames = []
    ss_file_items.each {|item| filenames.push(item.name)}
    filename_duplicate_flag = filenames.size == filenames.uniq.size ? 0 : 1

    zipfile = Gws::Share::Folder.where(id: params[:id]).first.name + ".zip"
    folder_updated_time = Gws::Share::Folder.where(id: params[:id]).first.updated

    @model.create_download_directory(File.dirname(@model.zip_path(params[:id])))
    @model.create_zip(@model.zip_path(params[:id]), ss_file_items, filename_duplicate_flag, folder_updated_time)
    send_file(@model.zip_path(params[:id]), type: 'application/zip', filename: zipfile, disposition: 'attachment')
  end

end
