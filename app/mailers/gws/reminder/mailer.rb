class Gws::Reminder::Mailer < ActionMailer::Base
  helper Gws::Schedule::PlanHelper

  def notify_mail(reminder)
    @reminder = reminder
    @item = reminder.item

    from = format_email(reminder.user)
    return nil if from.blank?
    to = from

    subject = I18n.t(
      "gws.reminder.notification.subject",
      model: I18n.t("mongoid.models.#{reminder.model}"),
      name: @item.name)

    mail(from: from, to: to, subject: subject)
  end

  def format_email(user)
    return nil if user.email.blank?

    if user.name.present?
      "#{user.name} <#{user.email}>"
    else
      user.email
    end
  end
end
