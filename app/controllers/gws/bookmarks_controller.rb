class Gws::BookmarksController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Bookmark

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_bookmark_label || t("mongoid.models.gws/bookmark"), action: :index]
  end

  public

  def index
    @items = @model.site(@cur_site).
      user(@cur_user).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
