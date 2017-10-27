class Gws::Report::NotificationJob < Gws::ApplicationJob
  def perform(item_id, added_member_ids, removed_member_ids)
    item = Gws::Report::File.site(site).find(item_id)

    sender = item.user
    sender_email = format_email(sender) || default_from_email
    Gws::User.in(id: added_member_ids).each do |recipient|
      recipient_email = format_email(recipient)
      next if recipient_email.blank?

      mail = Gws::Report::Mailer.publish_mail(item, from: sender_email, to: recipient_email)
      next if mail.blank?

      mail.deliver_now
    end

    Gws::User.in(id: removed_member_ids).each do |recipient|
      recipient_email = format_email(recipient)
      next if recipient_email.blank?

      mail = Gws::Report::Mailer.depublish_mail(item, from: sender_email, to: recipient_email)
      next if mail.blank?

      mail.deliver_now
    end
  end

  private

  def format_email(user)
    return nil if user.email.blank?

    if user.name.present?
      "#{user.name} <#{user.email}>"
    else
      user.email
    end
  end

  def default_from_email
    site.sender_address
  end
end
