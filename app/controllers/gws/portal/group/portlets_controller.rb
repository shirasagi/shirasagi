class Gws::Portal::Group::PortletsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter
  include Gws::Portal::GroupPortalFilter
  include Gws::Portal::PortletFilter

  model Gws::Portal::GroupPortlet

  prepend_view_path 'app/views/gws/portal/common/portlets'
  navi_view 'gws/portal/main/navi'

  before_action :set_portal_setting
  before_action :check_portal_permission, except: %i[delete destroy]
  before_action :save_portal_setting

  private

  def set_crumbs
    set_portal_setting
    @crumbs << [@portal.name, gws_portal_group_path]
    @crumbs << [t("gws/portal.links.manage_portlets"), action: :index]
  end

  def check_portal_permission
    raise "403" unless @portal.allowed?(:edit, @cur_user, site: @cur_site)
  end
end
