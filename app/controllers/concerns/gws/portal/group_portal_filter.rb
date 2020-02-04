module Gws::Portal::GroupPortalFilter
  extend ActiveSupport::Concern

  private

  def set_portal_setting
    return if @portal
    return if params[:group].blank?

    @portal_group = Gws::Group.find(params[:group])
    @portal = @portal_group.find_portal_setting(cur_user: @cur_user, cur_site: @cur_site)
    @portal.portal_type = (@portal_group.id == @cur_site.id) ? :root_portal : :group_portal

    raise '403' unless @portal.portal_readable?(@cur_user, site: @cur_site)
  end

end
