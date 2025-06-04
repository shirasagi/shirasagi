class Gws::Affair2::Management::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair2::BaseFilter
  include Gws::Affair2::YearMonthFilter
  include Gws::Affair2::TimeCardFilter

  model Gws::Affair2::Attendance::TimeCard

  navi_view "gws/affair2/management/main/navi"

  before_action :set_attendance_date
  before_action :set_active_year_range
  before_action :set_cur_month
  before_action :set_groups
  helper_method :attendance_date?, :punchable?, :editable?

  helper_method :default_year_month, :year_month_options
  helper_method :default_group, :group_options

  private

  # 管理者タイムカードは管理年数
  def set_active_year_range
    years = (-1 * @cur_site.affair2_management_year)
    @active_year_range ||= begin
      start_date = @attendance_date.advance(years: years).change(day: 1).to_date
      close_date = @attendance_date.advance(years: 1).change(day: 1).to_date
      [start_date, close_date]
    end
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair2_label || t('modules.gws/affair2'), gws_affair2_main_path ]
  end

  def set_groups
    @groups = Gws::Group.in_group(@cur_site).active

    if @model.allowed?(:manage_all, @cur_user, site: @cur_site)
      @groups = Gws::Group.in_group(@cur_site).active
    elsif @model.allowed?(:manage_sub, @cur_user, site: @cur_site)
      cond = @cur_user.groups.map do |item|
        { name: /^#{::Regexp.escape(item.name)}(\/|$)/ }
      end
      @groups = Gws::Group.in_group(@cur_site).and({ "$or" => cond }).active
    else
      @groups = Gws::Group.none
    end

    @group = @groups.find { |item| item.id == params[:group].to_i }
    raise "404" if @group.nil?
  end

  def group_options
    @groups.map { |g| [g.name, g.id] }
  end

  def set_items
    @users = @group.users.active.order_by_title(@cur_site)
    @items = @model.site(@cur_site).in(user_id: @users.pluck(:id)).where(date: @cur_month)
  end

  def default_year_month
    @default_year_month ||= @attendance_date.strftime('%Y%m')
  end

  def default_group
    @default_group ||= @cur_group.id
  end

  public

  def index
    set_items
    @time_cards = {}
    @items.each do |item|
      @time_cards[item.user_id] = item
    end
  end

  def show
    set_item
    @today = @cur_site.affair2_attendance_date

    @loader = Gws::Affair2::Loader::Monthly::View.new(@item, view_context)
    @loader.load
  end

  def setting
    set_item
    @today = @cur_site.affair2_attendance_date
  end

  def lock
    set_items

    if request.get? || request.head?
      user_ids = @items.and_unlocked.pluck(:user_id)
      @target_users = Gws::User.in(id: user_ids).active
      if @target_users.blank?
        redirect_to({ action: :index, s: params[:s].try(:to_unsafe_h) }, { notice: t('gws/attendance.no_target_users') })
      end
      return
    end

    unless params[:item]
      redirect_to({ action: :index, s: params[:s] }, { notice: t('gws/attendance.no_target_users') })
      return
    end

    safe_params = params.require(:item).permit(user_ids: [])
    user_ids = Gws::User.in(id: safe_params[:user_ids]).active.pluck(:id)
    render_update @items.in(user_id: user_ids).lock_all(@cur_site), location: { action: :index },
      render: { template: "lock" }, notice: t("gws/affair2.notice.started_lock")
  end

  def unlock
    set_items

    if request.get? || request.head?
      user_ids = @items.and_locked.pluck(:user_id)
      @target_users = Gws::User.in(id: user_ids).active
      if @target_users.blank?
        redirect_to({ action: :index, s: params[:s].try(:to_unsafe_h) }, { notice: t('gws/attendance.no_target_users') })
      end
      return
    end

    unless params[:item]
      redirect_to({ action: :index, s: params[:s] }, { notice: t('gws/attendance.no_target_users') })
      return
    end

    safe_params = params.require(:item).permit(user_ids: [])
    user_ids = Gws::User.in(id: safe_params[:user_ids]).active.pluck(:id)
    render_update @items.in(user_id: user_ids).unlock_all(@cur_site), location: { action: :index },
      render: { template: "unlock" }, notice: t("gws/affair2.notice.started_unlock")
  end

  def delete
    #raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    #raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  ##

  def attendance_date?(date)
    date.to_date == @today.to_date
  end

  def punchable?(item)
    false
  end

  def editable?(item)
    @editable ||= {}
    @editable[item.id] ||= (item.allowed?(:edit, @cur_user, site: @cur_site) && item.unlocked?)
  end
end
