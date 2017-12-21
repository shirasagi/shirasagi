module Gws::Addon
  module Reminder
    extend ActiveSupport::Concern
    extend SS::Addon

    attr_accessor :reminder_url, :in_reminder_state, :in_reminder_date

    included do
      permit_params :reminder_url, :in_reminder_state, :in_reminder_date

      after_save :save_reminders
      after_destroy ->{ reminders.destroy }
    end

    # Has many reminders
    def reminders
      @reminders ||= Gws::Reminder.where(model: reference_model, item_id: id)
    end

    def reminder(user = @cur_user)
      @reminder ||= reminders.user(user).first
    end

    def in_reminder_state
      return @in_reminder_state if @in_reminder_state
      return 'enabled' if new_record?
      reminder ? 'enabled' : 'disabled'
    end

    def in_reminder_date
      if @in_reminder_date
        date = Time.zone.parse(@in_reminder_date) rescue nil
      end
      date ||= reminder ? reminder.date : (reminder_date || Time.zone.now + 7.day)
      date
    end

    def reminder_date
      try(:start_at)
    end

    def reminder_url
      name = reference_model.tr('/', '_') + '_path'
      [name, id: id]
    end

    def reminder_user_ids
      [@cur_user.try(:id), user_id].compact
    end

    private

    def save_reminders
      return if reminder_url.blank?
      return if @db_changes.blank?

      new_record = @db_changes.key?('_id')
      removed_user_ids = reminders.map(&:user_id) - reminder_user_ids
      removed_user_ids << @cur_user.id if @cur_user && @in_reminder_state == 'disabled'

      base_cond = {
        site_id: site_id,
        model: reference_model,
        item_id: id
      }
      self_updated_fields = @db_changes.keys.reject { |s| s =~ /_hash$/ }

      ## save reminders
      reminder_user_ids.each do |user_id|
        next if removed_user_ids.include?(user_id)

        cond = base_cond.merge(user_id: user_id)
        item = Gws::Reminder.where(cond).first || Gws::Reminder.new(cond)
        item.name = reference_name
        item.date = @in_reminder_date || reminder_date
        item.updated_fields = self_updated_fields unless new_record
        if @cur_user
          item.updated_user_id = @cur_user.id
          item.updated_user_uid = @cur_user.uid
          item.updated_user_name = @cur_user.name
          item.updated_date = updated
        end
        item.save if item.changed?
      end

      ## delete reminders
      cond = base_cond.merge(:user_id.in => removed_user_ids)
      Gws::Reminder.where(cond).destroy_all
    end
  end
end
