class Gws::Presence::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Presence::UserFilter

  private

  def set_crumbs
    set_group
    @crumbs << [t("modules.gws/presence"), gws_presence_users_path]
  end

  def set_group
    @custom_groups = Gws::CustomGroup.site(@cur_site).member(@cur_user)
  end

  def items
    @items = @model.site(@cur_site).active.search(params[:s]).order_by_title(@cur_site).
      page(params[:page]).per(25)
  end

  public

  def index
    items
    @table_url = table_gws_presence_users_path(site: @cur_site)
    @paginate_params = { controller: 'gws/presence/users', action: 'index' }
  end

  def table
    items
    render template: "table", layout: false
  end
end
