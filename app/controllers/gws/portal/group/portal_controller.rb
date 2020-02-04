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
    @crumbs << [@portal.name, gws_portal_group_path]
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
