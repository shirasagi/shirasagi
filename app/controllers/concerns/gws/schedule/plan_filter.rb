module Gws::Schedule::PlanFilter
  extend ActiveSupport::Concern
  include Gws::Schedule::CalendarFilter

  included do
    model Gws::Schedule::Plan
    before_action :check_schedule_visible
    before_action :set_file_addon_state
  end

  private

  def check_schedule_visible
    raise '404' unless @cur_site.menu_schedule_visible?
  end

  def set_crumbs
    @crumbs << [t('modules.gws/schedule'), gws_schedule_main_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    @skip_default_group = true
    {
      start_at: params[:start] || Time.zone.now.strftime('%Y/%m/%d %H:00'),
      member_ids: params[:member_ids].presence || [@cur_user.id],
      facility_ids: params[:facility_ids].presence
    }
  end

  def redirection_view
    params.dig(:calendar, :view).presence || 'month'
  end

  def redirection_url
    url_for(action: :index) + "?calendar[view]=#{redirection_view}&calendar[date]=#{@item.start_at.to_date}"
  end

  def set_file_addon_state
    @file_addon_state = 'hide' if @cur_site.schedule_attachment_denied?
  end

  def send_approval_mail
    Gws::Memo::Notifier.deliver_workflow_request!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: @item.all_approvers, item: @item,
      url: url_for(action: :show)
    ) rescue nil
  end

  public

  def index
    render
  end

  def show
    raise '403' unless @item.readable?(@cur_user, site: @cur_site)
    render
  end

  def events
    @items = []
  end

  def print
    @portrait = 'horizontal'
    render file: 'print', layout: 'ss/print'
  end

  def create
    @item = @model.new get_params
    @item.set_facility_column_values(params)
    @item.reset_approvals
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    saved = @item.save
    render_create saved, location: redirection_url
    send_approval_mail if saved && @item.approval_present?
  end

  def update
    @item.attributes = get_params
    @item.set_facility_column_values(params)
    @item.reset_approvals
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    saved = @item.update
    render_update saved, location: redirection_url
    send_approval_mail if saved && @item.approval_present?
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    @item.edit_range = params.dig(:item, :edit_range)
    render_destroy @item.destroy
  end

  def copy
    set_item
    @item = @item.new_clone
    render file: :new
  end
end
