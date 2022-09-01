class Gws::BookmarksController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Bookmark

  private

  def pre_params
    { bookmark_model: Gws::Bookmark::FALLBACK_BOOKMARK_MODEL_TYPE }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_bookmark_label || t("mongoid.models.gws/bookmark"), action: :index]
  end

  def set_item
    super
    raise "404" unless @item.user_id == @cur_user.id
    raise "404" unless @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    @items = @model.site(@cur_site).
      user(@cur_user).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
