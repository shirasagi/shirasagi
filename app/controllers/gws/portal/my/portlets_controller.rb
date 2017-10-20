class Gws::Portal::My::PortletsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter

  model Gws::Portal::MyPortlet

  navi_view 'gws/portal/my/navi'

  before_action :set_portal_setting
  before_action :save_portal_setting

  private

  def set_crumbs
    @crumbs << [t("gws/portal.my_portal"), gws_portal_path]
    @crumbs << [t("gws/portal.links.manage_portlets"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, setting_id: @portal.try(:id) }
  end

  public

  def index
    @items = @portal.portlets.
      search(params[:s])
  end

  def new
    new_portlet
  end
end
