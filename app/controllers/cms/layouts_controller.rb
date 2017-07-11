class Cms::LayoutsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Layout

  navi_view "cms/main/navi"

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
      search_layouts(params.dig(:s, :search_layouts), @cur_node).
      allow(:read, @cur_user).
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end
end
