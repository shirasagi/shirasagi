class Gws::Portal::User::PortalController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter

  model Gws::Portal::UserSetting

  before_action :set_portal_setting

  navi_view "gws/portal/main/navi"

  private

  def set_crumbs
    set_portal_setting

    if /^#{::Regexp.quote(gws_portal_path)}\/?$/.match?(request.path)
      @crumbs << [t("modules.gws/portal"), gws_portal_path]
    else
      #@crumbs << [t("gws/portal.user_portal"), gws_portal_setting_users_path]
      @crumbs << [@portal_user.name, gws_portal_user_path(user: @portal_user)]
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_item
    set_portal_setting
    @item = @portal
  end
end
