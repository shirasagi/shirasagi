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

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
