class Gws::Portal::MainController < ApplicationController
  include Gws::BaseFilter

  private

  def set_crumbs
    @crumbs << [t("modules.gws/portal"), gws_portal_path]
  end

  public

  def show
    if @cur_user.gws_role_permit_any?(@cur_site, :use_gws_portal_user_settings)
      redirect_to gws_portal_user_path(user: @cur_user)
      return
    elsif @cur_user.gws_role_permit_any?(@cur_site, :use_gws_portal_organization_settings)
      redirect_to gws_portal_group_path(group: @cur_site)
      return
    elsif @cur_group.id != @cur_site.id && @cur_user.gws_role_permit_any?(@cur_site, :use_gws_portal_group_settings)
      redirect_to gws_portal_group_path(group: @cur_group)
      return
    end

    render
  end
end
