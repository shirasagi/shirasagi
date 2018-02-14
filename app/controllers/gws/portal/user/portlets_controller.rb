class Gws::Portal::User::PortletsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter
  include Gws::Portal::PortletFilter

  model Gws::Portal::UserPortlet

  prepend_view_path 'app/views/gws/portal/common/portlets'
  navi_view 'gws/portal/main/navi'

  before_action :set_portal_setting
  before_action :save_portal_setting

  private

  def set_crumbs
    set_portal_setting
    @crumbs << [@cur_site.menu_portal_label || t("modules.gws/portal"), gws_portal_path]
    @crumbs << [@portal_user.name, gws_portal_user_path(user: @portal_user)]
    @crumbs << [t("gws/portal.links.manage_portlets"), action: :index]
  end
end
