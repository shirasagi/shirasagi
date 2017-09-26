module Gws::Reference
  module Schedule
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_schedule

    included do
      belongs_to :schedule, class_name: 'Gws::Schedule::Plan'

      validates :schedule_id, presence: true
      before_validation :set_schedule_id, if: ->{ @cur_schedule }

      scope :schedule, ->(schedule) { where( schedule_id: schedule.id ) }
    end

    private

    def set_schedule_id
      self.schedule_id ||= @cur_schedule.id
    end
  end
end
