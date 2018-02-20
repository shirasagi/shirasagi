class Gws::NoticeNotificationJob < Gws::ApplicationJob
  def perform
    @now = Time.zone.now
    select_items
    send_all_notifications
  end

  private

  def select_items
    criteria = Gws::Notice.site(site).and_public
    criteria = criteria.and('$or' => [{ message_notification: 'enabled' }, { email_notification: 'enabled' }])
    @items = criteria.exists(notification_noticed: false)
  end

  def send_all_notifications
    each_item do |item|
      next if item.notification_noticed.present?

      criteria = Gws::Notice.where(id: item.id)
      item = criteria.find_one_and_update({ '$set' => { notification_noticed: @now } }, return_document: :after)
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
    if notice.message_notification == 'enabled'
      send_notification_by_message(notice)
    end

    if notice.email_notification == 'enabled'
      send_notification_by_email(notice)
    end
  end

  def send_notification_by_message(notice)
    path = Rails.application.routes.url_helpers.gws_public_notice_url(
      protocol: site.canonical_scheme, host: site.canonical_domain, site: site, id: notice
    )

    i18n_key = Gws::Notice.model_name.i18n_key
    subject = I18n.t("gws_notification.#{i18n_key}.subject", name: notice.name, default: notice.name)
    text = ApplicationController.helpers.sanitize(notice.html.presence || '', tags: [])
    text = text.truncate(60)
    text = I18n.t("gws_notification.#{i18n_key}.text", name: notice.name, text: text, path: path, default: text)

    message = Gws::Memo::Notice.new
    message.cur_site = site
    message.cur_user = user
    message.member_ids = select_recipients(notice).pluck(:id)
    message.send_date = @now
    message.subject = subject
    message.format = 'text'
    message.text = text

    message.save!
  end

  def send_notification_by_email(notice)
    select_recipients(notice).pluck(:email).compact.uniq.each do |email|
      next if email.blank?

      mail = Gws::Notice::Mailer.notify_mail(site, notice, email)
      next if mail.blank?

      mail.deliver_now
      Rails.logger.info("#{notice.name}: #{email}へ通知送信")
    end
  end

  def select_recipients(notice)
    user_ids = notice.readable_members.pluck(:id)
    user_ids += Gws::User.in(group_ids: notice.readable_groups.active.pluck(:id)).active
    user_ids.uniq!

    Gws::User.in(id: user_ids)
  end
end
