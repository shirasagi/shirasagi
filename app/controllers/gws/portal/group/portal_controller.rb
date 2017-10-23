class Gws::Portal::Group::PortalController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter

  model Gws::Portal::GroupSetting

  before_action :set_portal_setting

  private

  def set_crumbs
    if @cur_site.id.to_s == params[:group].to_s
      @crumbs << [t("gws/portal.root_portal"), gws_portal_group_path]
    else
      @crumbs << [t("gws/portal.group_portal"), gws_portal_group_path]
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
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
