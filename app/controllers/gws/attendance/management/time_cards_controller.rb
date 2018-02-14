class Gws::Attendance::Management::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Attendance::TimeCardFilter

  model Gws::Attendance::TimeCard

  before_action :check_model_permission
  before_action :set_groups
  before_action :set_active_year_range
  before_action :set_cur_month
  before_action :check_cur_month
  before_action :set_search_params
  before_action :set_items
  before_action :set_item, only: %i[show delete destroy time memo]
  before_action :set_record, only: %i[time memo]

  helper_method :year_month_options, :group_options

  navi_view "gws/attendance/main/navi"

  append_view_path 'app/views/gws/attendance/time_cards'

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_attendance_label || t('modules.gws/attendance'), gws_attendance_main_path]
    @crumbs << [t('ss.management'), gws_attendance_management_main_path]
  end

  def check_model_permission
    raise "403" unless %i[manage_private manage_all].any? { |priv| @model.allowed?(priv, @cur_user, site: @cur_site) }
  end

  def set_groups
    if @model.allowed?(:manage_all, @cur_user, site: @cur_site)
      @groups = Gws::Group.in_group(@cur_site).active
    elsif @model.allowed?(:manage_private, @cur_user, site: @cur_site)
      @groups = Gws::Group.in_group(@cur_group).active
    else
      @groups = Gws::Group.none
    end
  end

  def check_cur_month
    raise '404' if @cur_month < @active_year_range.first || @active_year_range.last < @cur_month
  end

  def set_search_params
    @s = OpenStruct.new(params[:s])
    if @s.group_id.present?
      @s.group = @groups.find(@s.group_id) rescue nil
    end
  end

  def set_items
    @items ||= begin
      criteria = @model.site(@cur_site).where(date: @cur_month).search(@s)
      criteria = criteria.in_groups(@groups)
      criteria
    end
  end

  def set_item
    @item = @items.find(params[:id])
    @item.attributes = fix_params
  end

  def set_record
    @cur_date = @cur_month.change(day: Integer(params[:day]))
    @record = @item.records.where(date: @cur_date).first_or_create
  end

  def crud_redirect_url
    if params[:action] == 'time' || params[:action] == 'memo'
      { action: :show }
    else
      super
    end
  end

  def year_month_options
    set_active_year_range

    options = []
    date = @active_year_range.last
    while date >= @active_year_range.first
      options << [l(date.to_date, format: :attendance_year_month), "#{date.year}#{format('%02d', date.month)}"]
      date -= 1.month
    end
    options
  end

  def group_options
    @groups.map { |g| [g.section_name, g.id] }
  end

  public

  def index
    @items = @items.page(params[:page]).per(50)
  end

  def show
    render
  end

  def delete
    render
  end

  def destroy
    render_destroy @item.destroy
  end

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      next if item.destroy

      item.errors.add :base, :auth_error
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def download
    @model = Gws::Attendance::DownloadParam

    if request.get?
      user_ids = @items.pluck(:user_id)
      @target_users = Gws::User.in(id: user_ids).active
      if @target_users.blank?
        redirect_to({ action: :index, s: params[:s] }, { notice: t('gws/attendance.no_target_users') })
      end
      return
    end

    @item = @model.new params.require(:item).permit(@model.permitted_fields).merge(fix_params)
    if @item.invalid?
      render_update false, render: { file: :download }
      return
    end

    time_cards = Gws::Attendance::TimeCard.site(@cur_site).in_groups(@groups)
    time_cards = time_cards.gte(date: @item.from_date.beginning_of_month)
    time_cards = time_cards.lte(date: @item.to_date.end_of_month)
    time_cards = time_cards.in(user_id: @item.user_ids)
    time_cards = time_cards.reorder(user_id: 1, date: 1)

    filename = "time_cards_#{Time.zone.now.to_i}.csv"
    send_enum(time_cards.enum_csv(@cur_site, @item), type: "text/csv; charset=#{@item.encoding}", filename: filename)
  end

  def lock
    if request.get?
      user_ids = @items.and_unlocked.pluck(:user_id)
      @target_users = Gws::User.in(id: user_ids).active
      if @target_users.blank?
        redirect_to({ action: :index, s: params[:s] }, { notice: t('gws/attendance.no_target_users') })
      end
      return
    end

    safe_params = params.require(:item).permit(user_ids: [])
    user_ids = Gws::User.in(id: safe_params[:user_ids]).active.pluck(:id)
    render_update @items.in(user_id: user_ids).lock_all, location: { action: :index }, render: { file: :lock }
  end

  def unlock
    if request.get?
      user_ids = @items.and_locked.pluck(:user_id)
      @target_users = Gws::User.in(id: user_ids).active
      if @target_users.blank?
        redirect_to({ action: :index, s: params[:s] }, { notice: t('gws/attendance.no_target_users') })
      end
      return
    end

    safe_params = params.require(:item).permit(user_ids: [])
    user_ids = Gws::User.in(id: safe_params[:user_ids]).active.pluck(:id)
    render_update @items.in(user_id: user_ids).unlock_all, location: { action: :index }, render: { file: :unlock }
  end
end
