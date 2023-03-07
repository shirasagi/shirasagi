class Gws::Bookmark::FoldersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Bookmark::BaseFilter

  model Gws::Bookmark::Folder

  navi_view "gws/bookmark/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_bookmark_label || t('modules.gws/bookmark'), gws_bookmark_main_path]
    @crumbs << [Gws::Bookmark::Folder.model_name.human, gws_bookmark_folders_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_item
    super
    @parent = @item.parent
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).user(@cur_user).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def create
    @item = @model.new get_params

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_create @item.save
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update, { controller: params["controller"] }
  end

  def move
    set_item
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @excepts = [@item.id] + @item.folders.map(&:id)
    if request.get? || request.head?
      render
      return
    end

    @item.attributes = params.require(:item).permit(:in_parent).merge(fix_params)
    @item.in_basename = {}
    @item.in_basename[I18n.default_locale] = @item.trailing_name

    render_update @item.save, notice: t("ss.notice.moved"), render: :move
  end
end
