module Gws::Reference
  module Schedules
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      embeds_ids :schedules, class_name: 'Gws::Schedule::Plan'
      permit_params schedule_ids: []
      scope :schedule, ->(schedule) { where(schedule_ids: schedule.id.to_s) }
    end
  end
end
