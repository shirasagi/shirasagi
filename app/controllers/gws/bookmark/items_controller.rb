class Gws::Bookmark::ItemsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Bookmark::BaseFilter

  model Gws::Bookmark::Item

  before_action :set_tree_navi, only: [:index]

  navi_view "gws/bookmark/main/navi"

  private

  def pre_params
    { bookmark_model: Gws::Bookmark::Item::BOOKMARK_MODEL_DEFAULT_TYPE, folder: (@folder || @root_folder) }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_bookmark_label || t("mongoid.models.gws/bookmark/item"), action: :index]
  end

  def set_item
    super
    raise "404" unless @item.user_id == @cur_user.id
    raise "404" unless @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_tree_navi
    @tree_navi = gws_bookmark_apis_folder_list_path(folder_id: params[:folder_id], format: 'json')
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).user(@cur_user)
    @items = @items.and_folder(@folder) if @folder
    @items = @items.search(params[:s]).
      page(params[:page]).per(50)
  end
end
