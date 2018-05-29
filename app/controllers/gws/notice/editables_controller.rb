class Gws::Notice::EditablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Notice::Post

  navi_view "gws/notice/main/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/notice/post"), action: :index]
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
