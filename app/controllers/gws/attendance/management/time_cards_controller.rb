class Gws::Attendance::Management::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Attendance::TimeCard

  before_action :check_model_permission
  before_action :set_cur_month
  before_action :set_items
  before_action :set_item, only: %i[show edit update delete destroy]

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

  def set_cur_month
    raise '404' if params[:year_month].blank? || params[:year_month].length != 6

    year = params[:year_month][0..3]
    month = params[:year_month][4..5]
    @cur_month = Time.zone.parse("#{year}/#{month}/01")
  end

  def set_items
    @items ||= begin
      criteria = @model.site(@cur_site).where(date: @cur_month).search(params[:s])
      if !@model.allowed?(:manage_all, @cur_user, site: @cur_site)
        criteria = criteria.in_groups(@cur_user.groups)
      end
      criteria
    end
  end

  def set_item
    @item = @items.find(params[:id])
  end

  public

  def index
    @items = @items.page(params[:page]).per(50)
  end

  def show
    render
  end
end
