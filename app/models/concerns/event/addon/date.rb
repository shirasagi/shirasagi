module Event::Addon
  module Date
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :event_name, type: String
      field :event_dates, type: Event::Extensions::EventDates
      permit_params :event_name, :event_dates

      validate :validate_event

      if respond_to?(:template_variable_handler)
        template_variable_handler('event_dates') do |name, issuer|
          template_variable_handler_event_dates(name, issuer)
        end
        template_variable_handler('event_dates.default') do |name, issuer|
          template_variable_handler_event_dates(name, issuer, :default)
        end
        template_variable_handler('event_dates.default_full') do |name, issuer|
          template_variable_handler_event_dates(name, issuer, :default_full)
        end
        template_variable_handler('event_dates.iso') do |name, issuer|
          template_variable_handler_event_dates(name, issuer, :iso)
        end
        template_variable_handler('event_dates.iso_full') do |name, issuer|
          template_variable_handler_event_dates(name, issuer, :iso_full)
        end
        template_variable_handler('event_dates.long') do |name, issuer|
          template_variable_handler_event_dates(name, issuer, :long)
        end
        template_variable_handler('event_dates.full') do |name, issuer|
          template_variable_handler_event_dates(name, issuer, :full)
        end
      end
    end

    private
      def validate_event
        errors.add :event_dates, :blank if event_name.present? && event_dates.blank?

        if event_dates.present?
          event_array = Event::Extensions::EventDates.mongoize event_dates
          errors.add :event_dates, :too_many_event_dates if event_array.size >= 180
        end
      end

      def template_variable_handler_event_dates(name, issuer, format = :default)
        event_dates = self[:event_dates]
        return "" unless event_dates.present?

        html = []
        dates = []
        term = []
        event_dates.each do |d|
          if term.blank? || term.last.tomorrow == d
            term << d
          else
            dates << term
            term = []
          end
        end
        dates << term if term.present?
        dates.each do |term|
          cls = "event-dates"

          if term.size != 1
            term = [term.first, term.last]
            cls = "event-dates period"
          end

          term = term.map do |d|
            "<time datetime=\"#{I18n.l d.to_date, format: :iso}\">#{I18n.l d.to_date, format: format.to_sym}</time>"
          end.join(" - ")
          html << "<span class=\"#{cls}\">#{term}</span>"
        end
        html.join
      end
  end
end
