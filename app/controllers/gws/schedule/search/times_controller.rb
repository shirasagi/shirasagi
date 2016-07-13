class Gws::Schedule::Search::TimesController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  def index
    @s = params[:s] || {}
    @schedule_params = {}
    or_cond = []

    if @s[:member_ids].class == Array
      @members = Gws::User.site(@cur_site).
        active.
        any_in(id: @s[:member_ids])

      if @members.present?
        @schedule_params[:member_ids] = @members.map(&:id)
        or_cond << { member_ids: { '$in' => @schedule_params[:member_ids] } }
      end
    end

    if @s[:facility_ids].class == Array
      @facilities = Gws::Facility::Item.site(@cur_site).
        readable(@cur_user, @cur_site).
        active.
        any_in(id: @s[:facility_ids])

      if @facilities.present?
        @schedule_params[:facility_ids] = @facilities.map(&:id)
        or_cond << { facility_ids: { '$in' => @schedule_params[:facility_ids] } }
      end
    end

    return @items = [] if or_cond.blank?

    sdate = Time.zone.today
    edate = sdate + 30.days

    min_hour = 8  # 08:00
    max_hour = 21 # 22:00
    @hours = (min_hour..max_hour).to_a

    plans = Gws::Schedule::Plan.site(@cur_site).
      between_dates(sdate, edate).
      and('$or' => or_cond)

    @items = plans.free_times(sdate, edate, min_hour, max_hour)
  end
end
