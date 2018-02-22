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
    @s = get_params

    @time_search = Gws::Schedule::PlanSearch.new(@s)
    @time_search.valid?

    @items = @time_search.search

    min_hour = params.dig(:d, :min_hour).presence || @cur_site.facility_min_hour || 8
    max_hour = params.dig(:d, :max_hour).presence || @cur_site.facility_max_hour || 22
    @hour_range = (min_hour.to_i...max_hour.to_i)

    render layout: false
  end
end
