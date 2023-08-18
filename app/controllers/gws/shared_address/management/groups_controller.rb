class Gws::SharedAddress::Management::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::SharedAddress::Group
  navi_view "gws/shared_address/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_shared_address_label || t("modules.gws/shared_address"), gws_shared_address_addresses_path]
    @crumbs << [t("mongoid.models.gws/shared_address/group"), action: :index]
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
