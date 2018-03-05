module Gws::Addon
  module Reminder
    extend ActiveSupport::Concern
    extend SS::Addon

    attr_accessor :in_reminder_conditions

    included do
      permit_params in_reminder_conditions: [:user_id, :state, :interval, :interval_type, :base_time]

      after_save :save_reminders, if: -> { in_reminder_conditions }
      after_save :update_reminders, if: -> { in_reminder_conditions.nil? }
      after_save :purge_reminders
      before_destroy :destroy_reminders
    end

    def reminder(user)
      Gws::Reminder.where(model: reference_model, item_id: id, site_id: site_id, user_id: user.id).first
    end

    def reminder_conditions(user)
      return [] if new_record?
      item = reminder(user)
      item ? item.notifications : []
    end

    def reminder_url
      name = reference_model.tr('/', '_') + '_path'
      [name, id: id, site: site_id]
    end

    def reminder_notify_state_options
      I18n.t("gws/reminder.options.notify_state").map do |k, v|
        [ v, k.to_s ]
      end
    end

    def reminder_interval_type_options
      I18n.t("gws/reminder.options.interval_type").map do |k, v|
        [ v, k.to_s ]
      end
    end

    def reminder_interval_type_allday_options
      I18n.t("gws/reminder.options.interval_type_allday").map do |k, v|
        [ v, k.to_s ]
      end
    end

    def reminder_base_time_options
      I18n.t("gws/reminder.options.base_time").map do |k, v|
        [ v, k.to_s ]
      end
    end

    def remove_repeat_reminder(base_plan)
      cond = {
        site_id: site_id,
        user_id: base_plan.cur_user.id,
        model: reference_model,
        item_id: id
      }
      Gws::Reminder.where(cond).destroy
    end

    def set_repeat_reminder_conditions(base_plan)
      self.cur_user = base_plan.cur_user
      self.in_reminder_conditions = base_plan.in_reminder_conditions
    end

    def validate_reminder_conditions(conditions)
      return if conditions.blank?
      conditions = conditions.map do |cond|
        if allday == "allday"
          base_at = Time.zone.parse("#{start_at.strftime("%Y/%m/%d")} #{cond["base_time"]}")
        else
          base_at = start_at
          cond.delete("base_time")
        end

        cond["interval"] = cond["interval"].to_i
        cond["notify_at"] = base_at - (cond["interval"].send(cond["interval_type"]))
        cond
      end
      conditions = conditions.uniq { |cond| cond["notify_at"] }
      conditions = conditions.sort_by { |cond| cond["notify_at"] }
      conditions
    end

    def apply_reminders(reminder, conditions)
      reminder.name = reference_name
      reminder.date = start_at
      reminder.start_at = start_at
      reminder.end_at = end_at
      reminder.allday = allday
      reminder.repeat_plan_id = repeat_plan_id

      # destroy old notifications
      reminder.notifications.destroy_all
      conditions.each do |cond|
        next if cond["state"] == "disabled"

        notification = reminder.notifications.new
        notification.notify_at = cond["notify_at"]
        notification.state = cond["state"]
        notification.interval = cond["interval"]
        notification.interval_type = cond["interval_type"]
        notification.base_time = cond["base_time"]

        if notification.notify_at < Time.zone.now
          notification.delivered_at = nil
        else
          notification.delivered_at = Time.zone.at(0)
        end
      end

      if @db_changes.present?
        reminder.updated_fields = @db_changes.keys.reject { |s| s =~ /_hash$/ } unless new_record?
        reminder.updated_user_id = @cur_user.id
        reminder.updated_user_uid = @cur_user.uid
        reminder.updated_user_name = @cur_user.name
        reminder.updated_date = updated
      end

      reminder.save!
      reminder
    end

    private

    def save_reminders
      return if reminder_url.blank?
      return if @db_changes.blank?
      return if @cur_user.blank?

      cond = {
        site_id: site_id,
        user_id: @cur_user.id,
        model: reference_model,
        item_id: id
      }
      reminder = Gws::Reminder.where(cond).first || Gws::Reminder.new(cond)
      self.in_reminder_conditions = validate_reminder_conditions(in_reminder_conditions)
      apply_reminders(reminder, in_reminder_conditions)

      reminder.reload
      reminder.destroy if reminder.notifications.blank?
    end

    def update_reminders
      return if reminder_url.blank?
      return if @db_changes.blank?
      return if @cur_user.blank?

      reminder = reminder(@cur_user)
      return unless reminder

      reminder.name = reference_name
      reminder.date = start_at
      reminder.start_at = start_at
      reminder.end_at = end_at
      reminder.allday = allday
      reminder.repeat_plan_id = repeat_plan_id

      reminder.notifications.each do |notification|
        if allday == "allday"
          base_at = Time.zone.parse("#{start_at.strftime("%Y/%m/%d")} #{notification.base_time}")
        else
          base_at = start_at
        end

        notification.notify_at = base_at - (notification.interval.send(notification.interval_type))
        if notification.notify_at < Time.zone.now
          notification.delivered_at = nil
        else
          notification.delivered_at = Time.zone.at(0)
        end
      end

      reminder.updated_fields = @db_changes.keys.reject { |s| s =~ /_hash$/ }
      reminder.updated_user_id = @cur_user.id
      reminder.updated_user_uid = @cur_user.uid
      reminder.updated_user_name = @cur_user.name
      reminder.updated_date = updated

      reminder.save!
    end

    def purge_reminders
      return if new_record?
      return if reminder_url.blank?
      return if @db_changes.blank?
      return if @cur_user.blank?

      if @db_changes["start_at"] || @db_changes["allday"]
        # remove other users item_id
        cond = {
          site_id: site_id,
          model: reference_model,
          item_id: id
        }
        Gws::Reminder.where(cond).ne(user_id: @cur_user.id).each do |item|
          item.unset(:item_id)
        end
      end

      if @db_changes["deleted"]
        # when soft deleted
        reminder = reminder(@cur_user)
        reminder.destroy if reminder
      end
    end

    def destroy_reminders
      return if @cur_user.blank?
      reminder = reminder(@cur_user)
      reminder.destroy if reminder
    end
  end
end
