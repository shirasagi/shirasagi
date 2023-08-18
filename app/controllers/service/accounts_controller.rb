class Service::AccountsController < ApplicationController
  include Service::BaseFilter
  include Service::AdminFilter
  include SS::CrudFilter

  model Service::Account

  private

  def set_crumbs
    @crumbs << [I18n.t('service.menu.accounts'), service_main_path]
  end

  def fix_params
    {}
  end

  public

  def index
    @items = Service::Account.all
  end

  def edit
    @item.set_quota_mb
  end
end
