class Gws::Affair::WorkingTime::Management::AggregateController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::User

  navi_view "gws/affair/main/navi"
  menu_view nil

  before_action :set_query

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/working_time/management/aggregate"), gws_affair_working_time_management_aggregate_path]
  end

  def set_query
    @current = Time.zone.now

    @groups = Gws::Group.in_group(@cur_site).active
    @year = (params.dig(:s, :year).presence || @current.year).to_i
    @month = (params.dig(:s, :month).presence || @current.month).to_i
    @group_id = params.dig(:s, :group_id).presence

    @s ||= OpenStruct.new params[:s]
    @s[:year] ||= @year
    @s[:month] ||= @month
  end

  def set_items
    if @group_id.present?
      group = @groups.where(id: @group_id).first
    else
      group = @cur_user.gws_main_group(@cur_site)
    end
    group ||= @cur_site
    @s[:group_id] ||= group.id
    @users = @model.active.in(group_ids: [group.id]).order_by_title(@cur_site)

    @users = @users.select do |user|
      duty_calendar = user.effective_duty_calendar(@cur_site)
      (params[:duty_type] == "flextime") ? duty_calendar.flextime? : !duty_calendar.flextime?
    end
  end

  def set_time_cards
    @time_cards = {}
    @unlocked_time_cards = []

    date = Time.new(@year, @month, 1, 0, 0, 0).in_time_zone
    @users.each do |user|
      title = I18n.t(
        'gws/attendance.formats.time_card_full_name',
        user_name: user.name, month: I18n.l(date.to_date, format: :attendance_year_month)
      )
      time_card = Gws::Attendance::TimeCard.site(@cur_site).user(user).where(date: date).first

      if !time_card || !time_card.locked?
        @unlocked_time_cards << title
      end

      @time_cards[user.id] = time_card
    end
  end

  public

  def index
    set_items
    set_time_cards
  end

  def download
    set_items
    set_time_cards

    return if request.get?

    safe_params = params.require(:s).permit(:encoding)
    encoding = safe_params[:encoding]
    filename = "working_time_#{Time.zone.now.to_i}.csv"
    enum_csv = Gws::Affair::Enumerator::WorkingTime.new(@cur_site, @users, @time_cards, OpenStruct.new(encoding: encoding))
    send_enum(enum_csv, type: "text/csv; charset=#{encoding}", filename: filename)
  end
end
