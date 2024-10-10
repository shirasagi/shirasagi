class Gws::Reminder::Mailer < ApplicationMailer
  helper Gws::Schedule::PlanHelper
  helper Gws::PublicUserProfile

  def notify_mail(site, reminder)
    @reminder = reminder
    @item = reminder.item

    from = site.sender_address
    to = format_email(reminder.user)
    to = site.exclude_disallowed_email(to)

    subject = I18n.t(
      "gws/reminder.notification.subject",
      model: I18n.t("mongoid.models.#{reminder.model}"),
      name: @item.name)

    mail(from: from, to: to, subject: subject, message_id: Gws.generate_message_id(site))
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
