class Gws::Schedule::PlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::Schedule::PlanFilter

  private
    def set_crumbs
      @crumbs << [:"modules.gws_schedule", gws_schedule_calendars_path]
    end
end
