module Event::Addon
  module CalendarList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      field :event_display, type: String, default: "list"
      field :event_display_tabs, type: Array, default: %w(list table)

      permit_params :event_display, event_display_tabs: []

      validates :event_display, inclusion: { in: %w(list table) }
      validate :validate_event_display_tabs
    end

    def event_display_options
      %w(list table map).map { |k| [I18n.t("event.options.event_display.#{k}"), k] }
    end

    %w(list table map).each do |k|
      define_method("event_display_#{k}?") do
        event_display_tabs.include?(k)
      end
    end

    private

    def validate_event_display_tabs
      return if event_display.blank?

      self.event_display_tabs = event_display_tabs.select(&:present?)
      if !event_display_tabs.include?(event_display)
        self.event_display_tabs << event_display
      end
    end
  end
end
