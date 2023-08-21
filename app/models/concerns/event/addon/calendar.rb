module Event::Addon
  module Calendar
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :event_display, type: String
      permit_params :event_display
      validates :event_display, inclusion: { in: %w(simple_table detail_table), allow_blank: true }
    end

    def event_display_options
      %w(simple_table detail_table).collect do |m|
        [ I18n.t("event.options.event_display.#{m}"), m ]
      end
    end
  end
end
