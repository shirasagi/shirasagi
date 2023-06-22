module Gws::Notice::PlanHelper
  extend ActiveSupport::Concern
  include Gws::Schedule::PlanHelper
  include Gws::Schedule::CalendarFilter::Transition

  def search_query
    params.to_unsafe_h.select { |k, v| k == 's' }.to_query
  end

  def calendar_format(plans, opts = {})
    events = plans.map do |m|
      m.calendar_format(@cur_user, @cur_site)
    end
    events.compact!
    events
  end
end
