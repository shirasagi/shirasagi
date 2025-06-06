class Gws::Affair2::Attendance::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair2::BaseFilter
  include Gws::Affair2::YearMonthFilter
  include Gws::Affair2::TimeCardFilter

  model Gws::Affair2::Attendance::Groups

  before_action :set_active_year_range, except: %i[main]
  before_action :set_cur_month, except: %i[main]
  before_action :set_cur_day, except: %i[main]

  helper_method :punchable?, :editable?
  helper_method :group_options, :default_group
  helper_method :day_options, :default_day
  helper_method :next_day, :prev_day
  helper_method :manageable_time_card?

  menu_view nil
  navi_view "gws/affair2/attendance/main/navi"

  private

  def required_attendance
    true
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path]
    @crumbs << [ t("modules.gws/affair2/attendance/group"), { action: :index } ]
  end

  def set_cur_day
    raise '404' if params[:day].blank?

    day = params[:day].to_i
    day = 1 if day < 1 || day > @cur_month.end_of_month.day
    @cur_day = @cur_month.change(day: day)
  end

  def day_options
    (1..@cur_month.end_of_month.day).map do |day|
      [I18n.t("gws/attendance.day", count: day), day]
    end
  end

  def default_day
    @default_year_month ||= @attendance_date.day
  end

  def group_options
    @group_options ||= @groups.map { |g| [g.name, g.id] }
  end

  def default_group
    @default_group ||= @cur_group.id
  end

  def next_day
    @next_day ||= begin
      date = @cur_day.advance(days: 1).to_date
      if date > @active_year_range.last.end_of_month
        false
      else
        url_for({ action: :index, year_month: date.strftime('%Y%m'), day: date.day })
      end
    end
  end

  def prev_day
    @prev_day ||= begin
      date = @cur_day.advance(days: -1).to_date
      if date < @active_year_range.first
        false
      else
        url_for({ action: :index, year_month: date.strftime('%Y%m'), day: date.day })
      end
    end
  end

  def punchable?(item)
    @punchable ||= {}
    @punchable[item.id] ||= (item.user_id == @cur_user.id && item.unlocked?)
  end

  def editable?(item)
    @editable ||= {}
    @editable[item.id] ||= (item.user_id == @cur_user.id && item.allowed?(:edit, @cur_user, site: @cur_site) && item.unlocked?)
  end

  public

  def main
    today = @cur_site.calc_attendance_date(Time.zone.now)
    redirect_to(action: :index, group: @cur_group.id, year_month: today.strftime('%Y%m'), day: today.day)
  end

  def index
    raise "403" if !@model.allowed_private?(:use, @cur_user, site: @cur_site, cur_group: @cur_group)

    @groups = @model.allowed_groups(:use, @cur_user, site: @cur_site, cur_group: @cur_group).active
    @group = @groups.find(params[:group]) rescue nil
    raise "403" if @group.nil?

    @item = @model.new(@cur_site, @group, @cur_day, view_context)
    @item.load
  end
end
