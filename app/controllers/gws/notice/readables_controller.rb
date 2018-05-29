class Gws::Notice::ReadablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Notice::Post

  navi_view "gws/notice/main/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/notice/post"), action: :index]
  end

  public

  def index
    @items = @model.site(@cur_site).and_public.
      readable(@cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def show
    raise "403" unless @model.site(@cur_site).and_public.readable(@cur_user, site: @cur_site).find(@item.id)
    render
  end
end
