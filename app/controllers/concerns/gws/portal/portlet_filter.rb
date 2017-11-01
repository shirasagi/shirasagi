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
    @addons = @item.portlet_addons if @item
  end

  def new_portlet
    @item = @model.new pre_params.merge(fix_params)
    @item.portlet_model = params[:portlet_model]
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item.name = @item.label(:portlet_model)
    @addons = @item.portlet_addons if @item.portlet_model
    render file: 'gws/portal/common/new_portlet' unless @item.portlet_model_enabled?
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
