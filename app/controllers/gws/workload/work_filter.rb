module Gws::Workload::WorkFilter
  extend ActiveSupport::Concern

  included do
    append_view_path 'app/views/gws/workload/main'

    model Gws::Workload::Work

    #before_action :set_crumbs
    before_action :set_clients
    before_action :set_loads
    before_action :set_cycles
    before_action :set_selected_user
    before_action :set_item, only: %i[show edit update disable delete destroy finish revert]
    before_action :set_selected_items, only: %i[active_all disable_all destroy_all set_seen_all unset_seen_all download_all]
    helper_method :category_options, :load_options, :client_options, :cycle_options, :search_group?
  end

  def finish
    @item.attributes = fix_params
    raise '403' if !@item.allowed?(:edit, @cur_user, site: @cur_site) && !@item.member?(@cur_user)
    @item.errors.clear
    return if request.get? || request.head?

    comment = Gws::Workload::WorkComment.new(cur_site: @cur_site, cur_user: @cur_user, cur_work: @item)
    comment.achievement_rate = 100
    result = comment.save
    result = @item.update if result
    render_update result
  end

  def revert
    @item.attributes = fix_params
    raise '403' if !@item.allowed?(:edit, @cur_user, site: @cur_site) && !@item.member?(@cur_user)
    @item.errors.clear
    return if request.get? || request.head?

    comment = Gws::Workload::WorkComment.new(cur_site: @cur_site, cur_user: @cur_user, cur_work: @item)
    comment.achievement_rate = 0
    result = comment.save
    result = @item.update if result
    render_update result
  end

  private

  def set_selected_user
    return if params[:user] == "-"
    @user = @users.find { |c| c.id == params[:user].to_i }
    redirect_to(user: "-") if @user.nil?
  end

  def set_clients
    @clients = Gws::Workload::Client.site(@cur_site).search_year(year: @year).to_a

    return if params[:client] == "-"
    @client = @clients.find { |c| c.id == params[:client].to_i }
    redirect_to(client: "-") if @client.nil?
  end

  def set_loads
    @loads = Gws::Workload::Load.site(@cur_site).search_year(year: @year).to_a
  end

  def set_cycles
    @cycles = Gws::Workload::Cycle.site(@cur_site).search_year(year: @year).to_a
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site}
  end

  def pre_params
    if @calendar_start
      due_date = @calendar_start
      due_start_on = @calendar_start - @cur_site.workload_default_due_date.day
      #due_end_on = @calendar_start
    else
      today = Time.zone.today
      due_date = today + @cur_site.workload_default_due_date.day
      due_start_on = today
      #due_end_on = today + @cur_site.workload_default_due_date.day
    end

    ret = {}
    ret[:due_date] = due_date
    ret[:due_start_on] = due_start_on
    #ret[:due_end_on] = due_end_on
    ret[:year] = @year if @year
    ret[:category_id] = @category.id if @category
    ret[:member_group_id] = @cur_group.id
    ret[:member_ids] = [@cur_user.id]
    ret
  end

  def item_deleted?
    @item.deleted?
  end

  def item_readable?
    @item.member?(@cur_user) || @item.readable?(@cur_user, site: @cur_site) || @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  def load_options
    @loads.map { |l| [l.name, l.id] }
  end

  def client_options
    @clients.map { |c| [c.name, c.id] }
  end

  def cycle_options
    @cycles.map { |c| [c.name, c.id] }
  end

  public

  def index
    @s = OpenStruct.new params[:s]
    @s[:site] = @cur_site
    @s[:year] = @year if @year.present?
    @s[:category_id] = @category.id if @category.present?
    @s[:client_id] = @client.id if @client.present?
    @s[:work_state] ||= "except_finished"
    @s[:sort] ||= "due_date"

    set_items
  end

  def create
    @item = @model.new get_params
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    render_create @item.save
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    render_update @item.update
  end

  def show
    raise '404' if item_deleted?

    if item_readable?
      render template: 'show'
    else
      render template: 'gws/schedule/plans/private_plan'
    end
  end

  def download_all
    raise '403' if @items.empty?

    csv = @items.
      reorder(updated: -1).
      to_csv.
      encode('SJIS', invalid: :replace, undef: :replace)

    send_data csv, filename: "workload_#{Time.zone.now.to_i}.csv"
  end
end
