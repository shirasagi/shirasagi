module Gws::Schedule::PlanFilter
  extend ActiveSupport::Concern
  include Gws::Schedule::CalendarFilter
  include Gws::Schedule::CalendarFilter::Transition

  included do
    model Gws::Schedule::Plan
    before_action :check_schedule_visible
    before_action :set_file_addon_state
    before_action :set_items
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
    {
      start_at: params[:start] || Time.zone.now.strftime('%Y/%m/%d %H:00'),
      member_ids: params[:member_ids].presence || [@cur_user.id],
      facility_ids: params[:facility_ids].presence
    }
  end

  def set_items
    @items ||= begin
      #or_conds = Gws::Schedule::Plan.member_conditions(@cur_user)
      #or_conds << { approval_member_ids: @cur_user.id }
      Gws::Schedule::Plan.site(@cur_site).without_deleted.
        member(@cur_user).
        #and([{ '$or' => or_conds }]).
        search(params[:s])
    end
  end

  # override SS::CrudFilter#set_item
  def set_item
    set_items
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def redirection_url
    path = params.dig(:calendar, :path)
    if path.present?
      uri = URI(path)
      uri.query = redirection_calendar_params.to_param
      uri.to_s
    else
      url_for(action: :index, calendar: redirection_calendar_params)
    end
  end

  def set_file_addon_state
    @file_addon_state = 'hide' if @cur_site.schedule_attachment_denied?
  end

  def send_approval_mail
    Gws::Schedule::Notifier::Approval.deliver_request!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: @item.all_approvers.nin(id: @cur_user.id), item: @item,
      url: url_for(action: :show, id: @item)
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

  def soft_delete
    set_item
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.deleted = Time.zone.now
    @item.edit_range = params.dig(:item, :edit_range)
    render_destroy @item.save, location: redirection_url
  end

  def undo_delete
    set_item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.deleted = nil
    @item.edit_range = params.dig(:item, :edit_range)
    @item.reset_approvals

    render_opts = {}
    render_opts[:location] = { action: :index }
    render_opts[:render] = { file: :undo_delete }
    render_opts[:notice] = t('ss.notice.restored')

    saved = @item.save
    flash[:errors] = @item.errors.full_messages if saved && @item.errors.present?
    render_update saved, render_opts
    send_approval_mail if saved && @item.approval_present?
  end
end
