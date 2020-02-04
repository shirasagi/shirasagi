module Gws::Portal::GroupPortalFilter
  extend ActiveSupport::Concern

  included do
    before_action :check_use_permission
  end

  private

  def set_portal_setting
    return if @portal
    return if params[:group].blank?

    @portal_group = Gws::Group.find(params[:group])
    @portal = @portal_group.find_portal_setting(cur_user: @cur_user, cur_site: @cur_site)
    @portal.portal_type = (@portal_group.id == @cur_site.id) ? :root_portal : :group_portal

    raise '403' unless @portal.portal_readable?(@cur_user, site: @cur_site)
  end

  def check_use_permission
    set_portal_setting

    permission_to_check = @portal_group.organization? ? :use_gws_portal_organization_settings : :use_gws_portal_group_settings
    raise '403' unless @cur_user.gws_role_permit_any?(@cur_site, permission_to_check)
  end
end
