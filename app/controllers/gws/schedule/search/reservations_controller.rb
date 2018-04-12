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
    return pre_params.merge(fix_params) if params[:s].blank?
    params.require(:s).permit(Gws::Schedule::PlanSearch.permitted_fields).merge(pre_params).merge(fix_params)
  end

  public

  def index
    @submit = params[:submit].present?

    @s = get_params
    @time_search = Gws::Schedule::PlanSearch.new(@s)
    @time_search.valid?

    @start_on = Time.zone.parse(@s[:start_on]) rescue nil
    @end_on = Time.zone.parse(@s[:end_on]) rescue nil

    @start_on = @start_on.to_date if @start_on && @s[:start_on] !~ /:/
    @end_on = @end_on.to_date if @end_on && @s[:end_on] !~ /:/

    @items = @time_search.search

    @hour_range = {}
    params_min_hour = params.dig(:d, :min_hour).presence
    params_max_hour = params.dig(:d, :max_hour).presence

    @reservation_valid = true
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

      if @reservation_valid
        @reservation_valid = (@hour_range[date].to_a - hours[1].values.flatten).blank?
      end
    end

    render layout: false
  end
end
