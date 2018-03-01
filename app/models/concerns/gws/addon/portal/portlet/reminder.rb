module Gws::Addon::Portal::Portlet
  module Reminder
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :reminder_filter, type: String
      permit_params :reminder_filter
    end

    def reminder_filter_options
      %w(all future).map { |v| [I18n.t("gws/portal.options.reminder_filter.#{v}"), v] }
    end

    def reminder_condition
      condition = { "deleted" => { "$exists" => false } }
      if reminder_filter == 'future'
        condition["date"] = { '$gte' => Time.zone.now }
      end
      condition
    end

    def find_reminder_items(portal, user)
      Gws::Reminder.site(portal.site).
        user(user).
        where(reminder_condition).
        page(1).
        per(limit)
    end
  end
end
