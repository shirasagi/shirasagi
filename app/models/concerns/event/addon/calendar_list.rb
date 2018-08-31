module Event::Addon
  module CalendarList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      field :event_display, type: String
      permit_params :event_display
      validates :event_display, inclusion: { in: ['list', 'table', 'list_only', 'table_only'], allow_blank: true }
    end

    def event_display_options
      %w(list table list_only table_only).collect do |m|
        [ I18n.t("event.options.event_display.#{m}"), m ]
      end
    end
  end
end
