class Gws::Report::NotificationJob < Gws::ApplicationJob
  def perform(item_id, added_member_ids, removed_member_ids)
    @item = Gws::Report::File.site(site).find(item_id)
    @user = @item.user

    if added_member_ids.present?
      Gws::User.in(id: added_member_ids).each do |recipient|
        mail = Gws::Report::Mailer.publish_mail(site, @item)
        next if mail.blank?
        create_memo_notice(mail, recipient)
      end
    end

    if removed_member_ids.present?
      Gws::User.in(id: removed_member_ids).each do |recipient|
        mail = Gws::Report::Mailer.depublish_mail(site, @item)
        next if mail.blank?
        create_memo_notice(mail, recipient)
      end
    end
  end

  private

  def create_memo_notice(mail, recipient)
    message = SS::Notification.new
    message.cur_group = site
    message.cur_user = @user
    message.member_ids = [recipient.id]
    message.send_date = Time.zone.now
    message.subject = mail.subject
    message.format = 'text'
    message.url = mail.decoded
    message.save!

    mail = Gws::Memo::Mailer.notice_mail(message, [recipient], @item)
    mail.deliver_now if mail
  end
end
