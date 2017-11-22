module Gws::Portal::PortletFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_portlet_addons
  end

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, setting_id: @portal.try(:id) }
  end

  def pre_params
    { group_ids: @portal.group_ids, user_ids: @portal.user_ids }
  end

  def set_portlet_addons
    portlet_model = params[:portlet_model].presence
    portlet_model = @item.portlet_model if @item
    @addons = @model.portlet_addons(portlet_model) if portlet_model
  end

  def new_portlet
    @item = @model.new pre_params.merge(fix_params)
    @item.portlet_model = params[:portlet_model]
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item.name = @item.label(:portlet_model)
    render file: 'gws/portal/common/portlets/select_model' unless @item.portlet_model_enabled?
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
