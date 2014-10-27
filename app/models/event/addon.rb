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

  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :schedule, type: String
      field :venue, type: String
      field :content, type: String
      field :cost, type: String
      field :related_url, type: String

      permit_params :schedule, :venue, :content, :cost, :related_url
    end

    set_order 180
  end

  module AdditionalInfo
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :additional_info, type: Event::Extensions::AdditionalInfo

      permit_params additional_info: [ :field, :value ]
    end

    set_order 190
  end

  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    set_order 200
  end
end
