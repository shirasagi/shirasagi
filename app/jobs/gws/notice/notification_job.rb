class Gws::Notice::NotificationJob < Gws::ApplicationJob
  def perform
    return unless site.notify_model?( Gws::Notice::Post)

    @now = Time.zone.now
    select_items
    send_all_notifications
  end

  private

  def select_items
    criteria = Gws::Notice::Post.site(site).without_deleted.and_public(@now)
    @items = criteria.exists(notification_noticed: false)
  end

  def send_all_notifications
    each_item do |item|
      next if item.notification_noticed.present?

      criteria = Gws::Notice::Post.where(id: item.id)
      item = criteria.find_one_and_update({ '$set' => { notification_noticed: @now.utc } }, return_document: :after)
      next unless item

      send_one_notification(item)
    end
  end

  def each_item(batch_size = 20)
    item_ids = @items.pluck(:id)
    item_ids.each_slice(batch_size) do |ids|
      items = @items.in(id: ids).to_a
      items.each do |item|
        yield item
      end
    end
  end

  def send_one_notification(notice)
    send_notification_by_message(notice)
  end

  def send_notification_by_message(notice)
    recipients = notice.overall_readers.site(@cur_site || site).active
    recipients = recipients.select{|recipient| recipient.id != user.id} if user
    recipients = recipients.select{|recipient| recipient.use_notice?(notice)}
    return if recipients.blank?

    path = Rails.application.routes.url_helpers.gws_notice_readable_path(
      protocol: site.canonical_scheme, host: site.canonical_domain, site: site, folder_id: '-', category_id: '-', id: notice
    )

    i18n_key = Gws::Notice::Post.model_name.i18n_key
    subject = I18n.t("gws_notification.#{i18n_key}.subject", name: notice.name, default: notice.name)
    text = ApplicationController.helpers.sanitize(notice.html.presence || '', tags: [])
    text = text.truncate(60)
    text = I18n.t("gws_notification.#{i18n_key}.text", name: notice.name, text: text, path: path, default: path)

    message = Gws::Memo::Notice.new
    message.cur_site = site
    message.cur_user = user
    message.member_ids = recipients.pluck(:id)
    message.send_date = @now
    message.subject = subject
    message.format = 'text'
    message.text = text

    message.save!

    Gws::Memo::Mailer.notice_mail(message, recipients, notice).try(:deliver_now)
  end

  def send_notification_by_email(notice)
    notice.overall_readers.site(@cur_site || site).active.pluck(:email).compact.uniq.each do |email|
      next if email.blank?

      mail = Gws::Notice::Mailer.notify_mail(site, notice, email)
      next if mail.blank?

      mail.deliver_now
      Rails.logger.info("#{notice.name}: #{email}へ通知送信")
    end
  end
end
