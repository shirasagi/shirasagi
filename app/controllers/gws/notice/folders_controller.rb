class Gws::Notice::FoldersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Notice::Folder

  navi_view "gws/notice/main/navi"

  private

  def set_crumbs
    @crumbs << [t('modules.gws/notice'), gws_notice_main_path]
    @crumbs << [Gws::Notice::Folder.model_name.human, gws_notice_folders_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    @items = @model.site(@cur_site).allow(:read, @cur_user, site: @cur_site)
  end

  def move
    set_item
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.attributes = get_params
    render_update @item.save, { controller: params["controller"] }
  end
end
