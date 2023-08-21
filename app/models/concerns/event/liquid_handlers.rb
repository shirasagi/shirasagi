module Event::LiquidHandlers
  extend ActiveSupport::Concern

  included do
    liquidize do
      export :event_name
      export as: :event_dates do
        if event_dates.blank?
          []
        else
          event_dates.clustered.map do |array|
            # probably, Time object is more convenient than Date object
            array.map(&:in_time_zone)
          end
        end
      end
      export :event_recurrences do
        event_recurrences.to_a.presence || []
      end
      export :event_deadline
    end
  end
end
