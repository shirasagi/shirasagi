class Gws::Portal::User::PortalController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter
  include Gws::Portal::UserPortalFilter

  model Gws::Portal::UserSetting

  before_action :set_portal_setting

  navi_view "gws/portal/main/navi"

  private

  def set_crumbs
    set_portal_setting

    if @cur_user == @portal_user
      @crumbs << [t("gws/portal.user_portal"), gws_portal_user_path]
    else
      @crumbs << [@portal_user.name, gws_portal_user_path]
    end
  end

  def set_item
    set_portal_setting
    @item = @portal
  end

  public

  def show
    show_portal
  end
end
