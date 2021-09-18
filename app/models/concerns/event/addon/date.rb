module Event::Addon
  module Date
    extend ActiveSupport::Concern
    extend SS::Addon

    MAX_EVENT_DATES_SIZE = 180

    included do
      field :event_name, type: String
      field :event_dates, type: Event::Extensions::EventDates
      field :event_deadline, type: DateTime
      permit_params :event_name, :event_dates, :event_deadline

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
        template_variable_handler('event_deadline') do |name, issuer|
          template_variable_handler_event_deadline(name, issuer)
        end
        template_variable_handler('event_deadline.default') do |name, issuer|
          template_variable_handler_event_deadline(name, issuer, :default)
        end
        template_variable_handler('event_deadline.iso') do |name, issuer|
          template_variable_handler_event_deadline(name, issuer, :iso)
        end
        template_variable_handler('event_deadline.long') do |name, issuer|
          template_variable_handler_event_deadline(name, issuer, :long)
        end
        template_variable_handler('event_deadline.full') do |name, issuer|
          template_variable_handler_event_deadline(name, issuer, :full)
        end
        template_variable_handler('event_deadline.short') do |name, issuer|
          template_variable_handler_event_deadline(name, issuer, :short)
        end
      end

      if respond_to? :liquidize
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
          export :event_deadline
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

      def gte_event_dates(start_date)
        all.where(:event_dates.gte => start_date)
      end

      def lte_event_dates(close_date)
        all.where(:event_dates.lte => close_date)
      end
    end

    def dates_to_html(format = :default)
      return "" unless event_dates.present?

      html = []

      event_dates.clustered.each do |range|
        cls = "event-dates"

        if range.size != 1
          range = [range.first, range.last]
          cls = "event-dates range"
        end

        range = range.map do |d|
          "<time datetime=\"#{I18n.l(d.to_date, format: :iso)}\">#{I18n.l(d.to_date, format: format.to_sym)}</time>"
        end.join("<span>#{I18n.t("event.date_range_delimiter")}</span>")

        html << "<span class=\"#{cls}\">#{range}</span>"
      end
      html.join("<br>")
    end

    private

    def validate_event
      errors.add :event_dates, :blank if event_name.present? && event_dates.blank?

      if event_dates.present? && event_dates.size > MAX_EVENT_DATES_SIZE
        errors.add :event_dates, :too_many_event_dates, count: MAX_EVENT_DATES_SIZE
      end
    end

    def template_variable_handler_event_dates(name, issuer, format = :default)
      dates_to_html(format)
    end

    def template_variable_handler_event_deadline(name, issuer, format = nil)
      return if self.event_deadline.blank?
      if format.nil?
        I18n.l self.event_deadline
      else
        I18n.l self.event_deadline, format: format.to_sym
      end
    end
  end
end
