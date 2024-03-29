class Cms::Ldap::ResultController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/ldap/main/navi"
  menu_view nil

  model Cms::Ldap::SyncTask

  private

  def fix_params
    { cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [t("ldap.result"), action: :index]
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @task = Cms::Ldap::SyncTask.site(@cur_site).first_or_create
    @items = @task.results
  end
end
