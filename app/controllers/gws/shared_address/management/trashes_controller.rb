class Gws::SharedAddress::Management::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::SharedAddress::Address

  navi_view "gws/shared_address/main/navi"

  append_view_path 'app/views/gws/shared_address/management/addresses'

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_shared_address_label || t("modules.gws/shared_address"), gws_shared_address_addresses_path]
    @crumbs << [t("ss.links.trash"), gws_shared_address_management_trashes_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    s_params = params[:s] || {}
    # s_params[:address_group_id] = @address_group.id if @address_group.present?

    @items = @model.site(@cur_site).
      allow(:trash, @cur_user, site: @cur_site).
      only_deleted.
      search(s_params).
      page(params[:page]).per(50)
  end
end
