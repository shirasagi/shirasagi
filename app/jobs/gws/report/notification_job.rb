class Gws::Report::NotificationJob < Gws::ApplicationJob
  def perform(item_id, added_member_ids, removed_member_ids)
    @item = Gws::Report::File.site(site).find(item_id)
    @user = @item.user

    if added_member_ids.present?
      Gws::User.in(id: added_member_ids).each do |recipient|
        mail = Gws::Report::Mailer.publish_mail(@item)
        next if mail.blank?
        create_memo_notice(mail, recipient)
      end
    end

    if removed_member_ids.present?
      Gws::User.in(id: removed_member_ids).each do |recipient|
        mail = Gws::Report::Mailer.depublish_mail(@item)
        next if mail.blank?
        create_memo_notice(mail, recipient)
      end
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

  def create_memo_notice(mail, recipient)
    message = Gws::Memo::Notice.new
    message.cur_site = site
    message.cur_user = @user
    message.member_ids = [recipient.id]
    message.send_date = Time.zone.now
    message.subject = mail.subject
    message.format = 'text'
    message.text = mail.decoded
    message.save!

    Gws::Memo::Mailer.notice_mail(message, [recipient], @item).try(:deliver_now)
  end
end
