class Gws::Portal::Group::PortletsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter
  include Gws::Portal::PortletFilter

  model Gws::Portal::GroupPortlet

  prepend_view_path 'app/views/gws/portal/common/portlets'
  navi_view 'gws/portal/main/navi'

  before_action :set_portal_setting
  before_action :save_portal_setting

  private

  def set_crumbs
    if @cur_site.id.to_s == params[:group].to_s
      @crumbs << [t("gws/portal.root_portal"), gws_portal_group_path]
    else
      @crumbs << [t("gws/portal.group_portal"), gws_portal_group_path]
    end
    @crumbs << [t("gws/portal.links.manage_portlets"), action: :index]
  end
end
