module Event::Addon
  module Date
    extend ActiveSupport::Concern
    extend SS::Addon

    MAX_EVENT_DATES_SIZE = 500

    included do
      field :event_name, type: String
      field :event_dates, type: Event::Extensions::EventDates
      field :event_recurrences, type: Event::Extensions::Recurrences
      field :event_deadline, type: DateTime

      permit_params :event_name, :event_deadline
      permit_params event_recurrences: [
        :in_update_from_view, :in_start_on, :in_until_on, :in_all_day, :in_start_time, :in_end_time, :in_exclude_dates,
        in_by_days: []
      ]

      before_validation :set_event_dates_from_recurrences
      validate :validate_event

      if respond_to?(:template_variable_handler)
        include Event::TemplateVariableHandlers
      end

      if respond_to? :liquidize
        include Event::LiquidHandlers
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

    def set_event_dates_from_recurrences
      self.event_dates = event_recurrences.collect_event_dates
    end

    def validate_event
      errors.add :event_dates, :blank_where_having_event_name if event_name.present? && event_dates.blank?

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
