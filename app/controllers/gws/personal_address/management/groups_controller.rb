class Gws::PersonalAddress::Management::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Webmail::AddressGroup

  navi_view "gws/personal_address/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_personal_address_label || t("modules.gws/personal_address"), gws_personal_address_addresses_path]
    @crumbs << [t("mongoid.models.gws/personal_address/group"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user }
  end

  public

  def index
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_gws_personal_addresses)

    @items = @model.user(@cur_user).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
