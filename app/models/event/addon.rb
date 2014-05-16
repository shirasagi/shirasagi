# coding: utf-8
module Event::Addon
  module Date
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 305

    included do
      field :event_name, type: String
      field :event_dates, type: Event::Extensions::EventDates
      permit_params :event_name, :event_dates
      
      validate :validate_event
    end

    def validate_event
      errors.add :event_dates, :blank if event_name.present? && event_dates.blank?

      if event_dates.present?
        event_array = Event::Extensions::EventDates.mongoize event_dates
        errors.add :event_dates, :too_many_event_dates if event_array.size >= 180
      end
    end
  end
end
