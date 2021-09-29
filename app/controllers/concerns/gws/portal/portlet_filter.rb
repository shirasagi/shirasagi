module Gws::Portal::PortletFilter
  extend ActiveSupport::Concern

  included do
    menu_view 'gws/portal/common/portlets/menu'
    before_action :set_portlet_addons
  end

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, setting_id: @portal.try(:id) }
  end

  def pre_params
    { readable_group_ids: @portal.group_ids, group_ids: @portal.group_ids, user_ids: @portal.user_ids }
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
    render template: 'gws/portal/common/portlets/select_model' unless @item.portlet_model_enabled?

    if params[:group].present?
      @default_readable_setting = proc do
        @item.readable_setting_range = 'select'
        @item.readable_group_ids = @portal.group_ids + [ @cur_group.id ]
      end
    elsif params[:user].present?
      @default_readable_setting = proc do
        @item.readable_setting_range = 'select'
        @item.readable_member_ids = @portal.user_ids + [ @cur_user.id ]
      end
    end
  end

  public

  def index
    @items = @portal.portlets.
      search(params[:s])
  end

  def new
    new_portlet
  end

  def reset
    raise '403' unless @portal.allowed?(:edit, @cur_user, site: @cur_site)
    return render(template: 'gws/portal/common/portlets/reset') unless request.post?

    @portal.portlets.destroy_all
    @portal.save_default_portlets

    redirect_to({ action: :index }, { notice: I18n.t('ss.notice.initialized') })
  end
end
