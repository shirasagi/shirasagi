module Gws::Addon
  module Reminder
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      after_save :update_reminders
      before_destroy ->{ reminders.destroy }
    end

    # Has many reminders
    def reminders
      @reminders ||= Gws::Reminder.where(item_collection: collection_name, item_id: id)
    end

    def reminder(user)
      @reminder ||= reminders.user(user).first
    end

    # abstract method
    def reminder_name
      name
    end

    # abstract method
    def reminder_date
      try :start_at
    end

    private
      def update_reminders
        reminders.update_all(name: reminder_name)
      end
  end
end
