class Service::MyAccountsController < ApplicationController
  include Service::BaseFilter
  include SS::CrudFilter

  model Service::Account
  #menu_view "ss/crud/resource_menu"

  private

  def set_crumbs
    @crumbs << [I18n.t('service.menu.my_account'), service_my_accounts_path]
  end

  def set_item
    @item = @cur_user
  end
end
