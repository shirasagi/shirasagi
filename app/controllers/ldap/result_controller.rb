class Ldap::ResultController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "ldap/main/navi"
  menu_view nil

  model Ldap::SyncTask

  private
    def fix_params
      { cur_site: @cur_site }
    end

    def set_crumbs
      @crumbs << [:"ldap.result", action: :index]
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @task = Ldap::SyncTask.site(@cur_site).first_or_create
      @items = @task.results
    end
end
