class Gws::Affair2::Leave::AchieveController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair2::BaseFilter

  model Gws::Affair2::Leave::Achieve

  navi_view "gws/affair2/attendance/main/navi"

  before_action :set_cur_month

  helper_method :group_options, :default_group
  helper_method :year_month_options, :default_year_month

  private

  def required_attendance
    true
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path ]
    @crumbs << [ t("modules.gws/affair2/leave/achieve"), action: :index ]
  end

  def set_cur_month
    raise '404' if params[:year_month].blank? || params[:year_month].length != 6
    year = params[:year_month][0..3]
    month = params[:year_month][4..5]
    @cur_month = Time.zone.parse("#{year}/#{month}/01")
  end

  def group_options
    @group_options ||= @groups.map { |g| [g.name, g.id] }
  end

  def default_group
    @default_group ||= @cur_group.id
  end

  def year_month_options
    @year_month_options ||= begin
      date = @attendance_date.change(day: 1).to_date
      start_date = date - 12.months
      close_date = date + 12.months

      options = []
      date = start_date
      while date <= close_date
        options << [ I18n.l(date.to_date, format: :attendance_year_month), "#{date.year}#{format('%02d', date.month)}" ]
        date += 1.month
      end
      options.reverse
    end
  end

  def default_year_month
    @default_year_month ||= @attendance_date.strftime('%Y%m')
  end

  def set_item
  end

  public

  def index
    raise "403" if !@model.allowed_private?(:use, @cur_user, site: @cur_site, cur_group: @cur_group)

    @groups = @model.allowed_groups(:use, @cur_user, site: @cur_site, cur_group: @cur_group).active
    @group = @groups.find(params[:group]) rescue nil
    raise "403" if @group.nil?

    @users = @group.users.active.order_by_title(@cur_site)
  end

  def show
    @groups = @model.allowed_groups(:use, @cur_user, site: @cur_site, cur_group: @cur_group).active
    @group = @groups.find(params[:group]) rescue nil
    raise "403" if @group.nil?

    @users = @group.users.active.order_by_title(@cur_site)
    @user = @users.find(params[:id]) rescue nil
    raise "403" if @user.nil?

    @item = @model.new(@cur_site, @cur_user, @group, @cur_month)
    @item.load
  end
end
