class Gws::PersonalAddress::Management::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Webmail::AddressGroup

  private

  def set_crumbs
    @crumbs << [t("modules.gws/personal_address"), gws_personal_address_addresses_path]
    @crumbs << [t("mongoid.models.gws/personal_address/group"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user }
  end

  public

  def index
    @items = @model.user(@cur_user).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
