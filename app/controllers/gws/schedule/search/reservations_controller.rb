class Gws::Schedule::Search::ReservationsController < ApplicationController
  include Gws::BaseFilter

  model Gws::Schedule::PlanSearch

  navi_view "gws/schedule/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    { min_hour: @cur_site.facility_min_hour || 8, max_hour: @cur_site.facility_max_hour || 22 }
  end

  def get_params
    return fix_params if params[:s].blank?
    params.require(:s).permit(Gws::Schedule::PlanSearch.permitted_fields).merge(fix_params)
  end

  def set_plan
    item_params = params[:item].to_unsafe_h
    item_params.delete(:facility_column_values)
    item_id = item_params[:id]

    if item_id.present?
      @plan = Gws::Schedule::Plan.find(item_id)
      @plan.attributes = item_params
    else
      @plan = Gws::Schedule::Plan.new item_params
    end
    @plan.cur_user = @cur_user
    @plan.cur_site = @cur_site

    @plan.user_id = @cur_user.id
    @plan.site_id = @cur_site.id
  end

  public

  def index
    set_plan
    @submit = params[:submit].present?

    @s = get_params
    @time_search = Gws::Schedule::PlanSearch.new(pre_params.merge(@s))
    @time_search.valid?

    @min_minutes_limit = []
    @max_minutes_limit = []
    @time_search.facilities.each do |facility|
      @min_minutes_limit << facility.min_minutes_limit if facility.min_minutes_limit
      @max_minutes_limit << facility.max_minutes_limit if facility.max_minutes_limit
    end
    @min_minutes_limit = @min_minutes_limit.max
    @max_minutes_limit = @max_minutes_limit.min

    @start_on = Time.zone.parse(@s[:start_on]) rescue nil
    @end_on = Time.zone.parse(@s[:end_on]) rescue nil

    @start_on = @start_on.to_date if @start_on && @s[:start_on] !~ /:/
    @end_on = @end_on.to_date if @end_on && @s[:end_on] !~ /:/

    @items = @time_search.search

    @hour_range = {}
    params_min_hour = params.dig(:d, :min_hour).presence
    params_max_hour = params.dig(:d, :max_hour).presence
    between_days = (@plan.end_at.to_date - @plan.start_at.to_date).to_i

    if between_days == 0

      @items.each do |date, hours|
        min_hour = params_min_hour || @cur_site.facility_min_hour || 8
        max_hour = params_max_hour || @cur_site.facility_max_hour || 22
        @hour_range[date] = (min_hour.to_i...max_hour.to_i)
      end

    else

      if @plan.repeat?
        @items.each do |date, hours|
          repeat_start = date
          repeat_end = date.advance(days: between_days)

          (repeat_start..repeat_end).each do |d|
            min_hour = @cur_site.facility_min_hour || 8
            max_hour = @cur_site.facility_max_hour || 22

            if (repeat_start == d) && params_min_hour
              min_hour = params_min_hour
            end
            if (repeat_end == d) && params_max_hour
              max_hour = params_max_hour
            end

            if @hour_range[d]
              exist_min = @hour_range[d].first
              exist_max = @hour_range[d].last

              min_hour = (exist_min < min_hour.to_i) ? exist_min : min_hour.to_i
              max_hour = (exist_max > max_hour.to_i) ? exist_max : max_hour.to_i
            end

            @hour_range[d] = (min_hour.to_i...max_hour.to_i)
          end
        end
      else
        @items.each do |date, hours|
          min_hour = @cur_site.facility_min_hour || 8
          max_hour = @cur_site.facility_max_hour || 22

          if (@time_search.start_on == date) && params_min_hour
            min_hour = params_min_hour
          end
          if (@time_search.end_on == date) && params_max_hour
            max_hour = params_max_hour
          end
          @hour_range[date] = (min_hour.to_i...max_hour.to_i)
        end
      end

    end

    render layout: false
  end
end
