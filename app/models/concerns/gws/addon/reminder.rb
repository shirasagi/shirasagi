module Gws::Addon
  module Reminder
    extend ActiveSupport::Concern
    extend SS::Addon

    attr_accessor :reminder_url

    included do
      permit_params :reminder_url

      after_create :create_reminders
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

    # abstract method
    #def reminder_user_ids
    #  [user_id]
    #end

    private
      def create_reminders
        return if reminder_url.blank?
        return unless respond_to?(:reminder_user_ids)

        reminder_user_ids.each do |user_id|
          reminder = Gws::Reminder.new(
            site_id: site_id,
            user_id: user_id,
            item_collection: collection_name,
            item_id: id,
            name: reminder_name,
            date: reminder_date,
            url: reminder_url.sub(/#id/, id.to_s)
          )
          reminder.save
        end
      end

      def update_reminders
        reminders.update_all(updated: updated, name: reminder_name)
      end
  end
end
