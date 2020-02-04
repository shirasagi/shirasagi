class Gws::Portal::Group::PortalController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter
  include Gws::Portal::GroupPortalFilter

  model Gws::Portal::GroupSetting

  before_action :set_portal_setting

  navi_view "gws/portal/main/navi"

  private

  def set_crumbs
    set_portal_setting
    if @portal_group == @cur_site
      @crumbs << [t("gws/portal.root_portal"), gws_portal_group_path]
    else
      @crumbs << [@portal_group.trailing_name, gws_portal_group_path]
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
