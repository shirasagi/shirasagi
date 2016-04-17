module Gws::Addon
  module Reminder
    extend ActiveSupport::Concern
    extend SS::Addon

    attr_accessor :reminder_url

    included do
      permit_params :reminder_url

      after_save :save_reminders
      after_destroy ->{ reminders.destroy }
    end

    # Has many reminders
    def reminders
      @reminders ||= Gws::Reminder.where(model: reference_model, item_id: id)
    end

    def reminder(user)
      @reminder ||= reminders.user(user).first
    end

    def reminder_date
      try :start_at
    end

    def reminder_url
      name = reference_model.tr('/', '_') + '_path'
      [name, id: id]
    end

    def reminder_user_ids
      [@cur_user.try(:id), user_id]
    end

    private
      def save_reminders
        return if reminder_url.blank?
        return if @db_changes.blank?

        new_record = @db_changes.key?('_id')
        removed_user_ids = reminders.map(&:user_id) - reminder_user_ids

        base_cond = {
          site_id: site_id,
          model: reference_model,
          item_id: id
        }

        ## save reminders
        reminder_user_ids.each do |user_id|
          cond = base_cond.merge(user_id: user_id)
          item = Gws::Reminder.where(cond).first || Gws::Reminder.new(cond)
          item.name = reference_name
          item.date = reminder_date
          item.updated_fields = @db_changes.keys unless new_record
          item.save if item.changed?
        end

        ## delete reminders
        cond = base_cond.merge(:user_id.in => removed_user_ids)
        Gws::Reminder.where(cond).destroy_all
      end
  end
end
