module Gws::Portal::PortletFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_addons, only: %w(show new create edit update)
  end

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, setting_id: @portal.try(:id) }
  end

  def set_addons
    @addons = @item.portlet_addons
  end

  public

  def index
    @items = @portal.portlets.
      search(params[:s])
  end

  def new
    new_portlet
  end
end
