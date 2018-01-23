class Gws::Attendance::Management::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Attendance::TimeCard

  before_action :check_model_permission
  before_action :set_groups
  before_action :set_cur_month
  before_action :set_search_params
  before_action :set_items
  before_action :set_item, only: %i[show edit update delete destroy]

  helper_method :year_month_options, :group_options

  private

  def set_crumbs
    @crumbs << [t('modules.gws/attendance'), gws_attendance_main_path]
    @crumbs << [t('ss.management'), gws_attendance_management_main_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def check_model_permission
    raise "403" if !@model.allowed?(:manage_private, @cur_user, site: @cur_site) && !@model.allowed?(:manage_all, @cur_user, site: @cur_site)
  end

  def set_groups
    if @model.allowed?(:manage_all, @cur_user, site: @cur_site)
      @groups = Gws::Group.in_group(@cur_site).active
    elsif @model.allowed?(:manage_private, @cur_user, site: @cur_site)
      @groups = @cur_user.groups.active
    else
      @groups = Gws::Group.none
    end
  end

  def set_cur_month
    raise '404' if params[:year_month].blank? || params[:year_month].length != 6

    year = params[:year_month][0..3]
    month = params[:year_month][4..5]
    @cur_month = Time.zone.parse("#{year}/#{month}/01")
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
  end

  def year_month_options
    options = []
    start_date = Time.zone.now.beginning_of_month
    end_date = start_date
    end_date -= 1.month while end_date.month != 4
    end_date = end_date - 3.years
    date = start_date
    while date >= end_date
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
end
