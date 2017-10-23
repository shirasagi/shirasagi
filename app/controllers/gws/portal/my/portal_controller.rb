class Gws::Portal::My::PortalController < ApplicationController
  include Gws::BaseFilter
  include Gws::Portal::PortalFilter

  before_action :set_portal_setting

  private

  def set_crumbs
    @crumbs << [t("gws/portal.my_portal"), gws_portal_path]
  end

  public

  def show
    @sys_notices = Sys::Notice.and_public.
      gw_admin_notice.
      page(1).per(5)

    @notices = Gws::Notice.site(@cur_site).and_public.
      readable(@cur_user, @cur_site).
      page(1).per(5)

    @links = Gws::Link.site(@cur_site).and_public.
      readable(@cur_user, @cur_site).to_a

    @items = @portal.readable_portlets(@cur_user, @cur_site)
  end
end
