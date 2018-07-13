class Gws::Questionnaire::NotificationJob < Gws::ApplicationJob
  def perform(*ids)
    @now = Time.zone.now
    select_items(ids)
    send_all_notifications
  end

  private

  def select_items(ids)
    criteria = Gws::Questionnaire::Form.site(site).without_deleted.and_public(@now)
    criteria = criteria.where(notification_notice_state: 'enabled')
    criteria = criteria.exists(notification_noticed_at: false)
    if ids.present?
      criteria = criteria.in(id: ids)
    end
    @items = criteria
  end

  def send_all_notifications
    Rails.logger.info("#{@items.count.to_s}件のアンケートがあります。")

    each_item do |item|
      next if item.notification_noticed_at.present?

      criteria = Gws::Questionnaire::Form.where(id: item.id)
      item = criteria.find_one_and_update({ '$set' => { notification_noticed_at: @now.utc } }, return_document: :after)
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

  def send_one_notification(item)
    return if item.notification_notice_state != 'enabled'

    recipients = item.overall_readers.site(@cur_site || site).active
    return if recipients.blank?

    path = Rails.application.routes.url_helpers.edit_gws_questionnaire_readable_file_url(
      protocol: site.canonical_scheme, host: site.canonical_domain,
      site: site, folder_id: '-', category_id: '-', readable_id: item
    )

    i18n_key = Gws::Questionnaire::Form.model_name.i18n_key
    subject = I18n.t("gws_notification.#{i18n_key}.subject", name: item.name, default: item.name)
    text = ApplicationController.helpers.sanitize(item.description.presence || '', tags: [])
    text = text.truncate(60)
    text = I18n.t("gws_notification.#{i18n_key}.text", name: item.name, text: text, path: path, default: text)

    message = Gws::Memo::Notice.new
    message.cur_site = site
    message.cur_user = user
    message.member_ids = recipients.pluck(:id)
    message.send_date = @now
    message.subject = subject
    message.format = 'text'
    message.text = text

    message.save!

    Rails.logger.info("#{item.name}: 通知送信")
  end
end
