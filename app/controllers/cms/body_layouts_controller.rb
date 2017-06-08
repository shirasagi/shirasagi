class Cms::BodyLayoutsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::BodyLayout

  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("cms.layout"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @items = @model.site(@cur_site).
      allow(:read, @cur_user).
      where(depth: 1).
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end

  def show
    # raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    render
  end
end
