class Gws::Portal::My::PortletsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter
  include Gws::Portal::PortletFilter

  model Gws::Portal::MyPortlet

  navi_view 'gws/portal/my/navi'

  before_action :set_portal_setting
  before_action :save_portal_setting

  private

  def set_crumbs
    @crumbs << [t("gws/portal.my_portal"), gws_portal_path]
    @crumbs << [t("gws/portal.links.manage_portlets"), action: :index]
  end
end
