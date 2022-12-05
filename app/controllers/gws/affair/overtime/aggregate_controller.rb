class Gws::Affair::Overtime::AggregateController < ApplicationController
  include Gws::BaseFilter
  include Gws::Affair::PermissionFilter
  include Gws::Affair::Aggregate::UsersFilter

  model Gws::Affair::OvertimeFile

  navi_view "gws/affair/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t('modules.gws/affair/overtime_file/aggregate'), gws_affair_overtime_aggregate_path]
  end

  public

  def index
    set_items
  end

  def show
    set_items
    @user = @users.select { |user| user.id == params[:uid].to_i }.first
    raise "403" if @user.nil?

    @item = Gws::Affair::LeaveSetting.and_date(@cur_site, @user, @cur_month).first

    prefs, aggregate = Gws::Affair::OvertimeDayResult.site(@cur_site).where(
      date_year: @cur_month.year,
      date_month: @cur_month.month,
      target_user_id: @user.id
    ).user_aggregate

    @under = prefs.dig(@user.id, "total", "under_threshold") || {}
    @over = prefs.dig(@user.id, "total", "over_threshold") || {}
    @aggregate = aggregate[@user.id] || {}
  end
end
