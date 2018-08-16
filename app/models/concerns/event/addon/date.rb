module Event::Addon
  module Date
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :event_name, type: String
      field :event_dates, type: Event::Extensions::EventDates
      permit_params :event_name, :event_dates

      validate :validate_event

      scope :gte_event_dates, ->(start_date){ where(:event_dates.gte => start_date) }
      scope :lte_event_dates, ->(close_date){ where(:event_dates.lte => close_date) }

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

    module ClassMethods
      def search(params = {})
        params ||= {}
        criteria = super

        if params[:dates].present?
          criteria = criteria.gte_event_dates(params[:dates].first)
          criteria = criteria.lte_event_dates(params[:dates].last)
        end

        if params[:start_date].present?
          criteria = criteria.gte_event_dates(params[:start_date])
        end

        if params[:close_date].present?
          criteria = criteria.lte_event_dates(params[:close_date])
        end

        criteria
      end
    end

    def dates_to_html(format = :default)
      return "" unless self[:event_dates].present?

      html = []

      get_event_dates.each do |range|
        cls = "event-dates"

        if range.size != 1
          range = [range.first, range.last]
          cls = "event-dates range"
        end

        range = range.map do |d|
          "<time datetime=\"#{I18n.l d.to_date, format: :iso}\">#{I18n.l d.to_date, format: format.to_sym}</time>"
        end.join("<span>#{I18n.t "event.date_range_delimiter"}</span>")
        html << "<span class=\"#{cls}\">#{range}</span>"
      end
      html.join
    end

    def get_event_dates
      event_dates = self[:event_dates]
      return "" unless event_dates.present?
      dates = []
      range = []
      event_dates.split(/\R/).each do |d|
        date = Time.zone.parse(d) rescue next
        if range.present? && range.last.tomorrow != date
          dates << range
          range = []
        end
        range << date
      end
      dates << range if range.present?
      dates
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
      dates_to_html(format)
    end
  end
end
