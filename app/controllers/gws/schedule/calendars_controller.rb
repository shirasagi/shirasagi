class Gws::Schedule::CalendarsController < ApplicationController
  include Gws::BaseFilter
  include Gws::Schedule::PlanFilter

  private
    def set_crumbs
      @crumbs << [:"modules.gws_schedule", gws_schedule_calendars_path]
    end

  public
    def index
      if params[:keyword].present?
        @plans = Gws::Schedule::Plan.any_of name: /.*#{params[:keyword]}.*/
      else
        @plans = Gws::Schedule::Plan.all
      end
    end
end
