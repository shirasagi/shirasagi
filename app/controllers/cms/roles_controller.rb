class Cms::RolesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Role

  prepend_view_path "app/views/ss/roles"
  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("cms.role"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      allow(:edit, @cur_user, site: @cur_site).
      order_by(name: 1).
      page(params[:page]).per(50)
  end
end
