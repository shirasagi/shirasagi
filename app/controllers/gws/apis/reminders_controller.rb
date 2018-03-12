class Gws::Apis::RemindersController < ApplicationController
  include Gws::ApiFilter
  include Gws::BaseFilter

  model Gws::Reminder

  public

  def create
    item = params[:item_model].camelize.constantize.find(params[:item_id])
    cond = {
      site_id: @cur_site.id,
      user_id: @cur_user.id,
      model: item.reference_model,
      item_id: item.id
    }
    reminder = Gws::Reminder.where(cond).first || Gws::Reminder.new(cond)
    conditions = item.validate_reminder_conditions(params.dig(:item, :in_reminder_conditions))
    item.apply_reminders(reminder, conditions)
    reminder.save!

    reminder.reload
    reminder.destroy if reminder.notifications.blank?

    render json: { reminder_conditions: (reminder.destroyed? ? [] : reminder.notifications) }
  end

  def destroy
    @now = Time.zone.now
    reminder = Gws::Reminder.find(params[:id])
    reminder.deleted = @now
    reminder.read_at = @now
    reminder.notifications.each do |notification|
      notification.delivered_at = nil
    end

    reminder.save!
    render plain: I18n.t('gws/reminder.notification.updated'), layout: false
  end

  def restore
    @now = Time.zone.now
    reminder = Gws::Reminder.find(params[:id])
    reminder.deleted = nil
    reminder.read_at = @now
    reminder.notifications.each do |notification|
      if notification.notify_at < @now
        notification.delivered_at = nil
      else
        notification.delivered_at = Time.zone.at(0)
      end
    end

    reminder.save!
    render plain: I18n.t('gws/reminder.notification.updated'), layout: false
  end
end
