class Gws::Schedule::Search::TimesController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  def index
    @items = []
    return if params.dig(:s, :member_ids).blank?

    safe_params = params.require(:s).permit(member_ids: [])
    @members = Gws::User.site(@cur_site).any_in(id: safe_params[:member_ids])
    return if @members.blank?

    sdate = Time.zone.today
    edate = sdate + 21.days

    min_hour = 8  # 08:00
    max_hour = 21 # 22:00
    @hours = (min_hour..max_hour).to_a

    plans = Gws::Schedule::Plan.site(@cur_site).
      any_in(member_ids: @members.map(&:id)).
      between_dates(sdate.to_s, edate.to_s)

    @items = plans.free_times(sdate, edate, min_hour, max_hour)
  end
end
