class Gws::Survey::NotificationJob < Gws::ApplicationJob
  def perform(*args)
    return unless site.notify_model?(Gws::Survey::Form)

    @now = Time.zone.now
    @options = args.extract_options!.with_indifferent_access
    @ids = args
    @cur_user_id = @options[:cur_user_id]
    select_items
    send_all_notifications
  end

  private

  def select_items
    criteria = Gws::Survey::Form.site(site).without_deleted.and_public(@now)
    if !@options[:unanswered_only]
      criteria = criteria.where(notification_notice_state: 'enabled')
    end
    if !@options[:resend]
      criteria = criteria.exists(notification_noticed_at: false)
    end
    if @ids.present?
      criteria = criteria.in(id: @ids)
    end
    @items = criteria
  end

  def send_all_notifications
    Rails.logger.info("#{@items.count.to_s(:delimited)}件のアンケートがあります。")

    each_item do |item|
      if !@options[:resend]
        if item.notification_noticed_at.present?
          Rails.logger.info("#{item.name}: 通知を送信済みです")
          next
        end

        criteria = Gws::Survey::Form.site(site).where(id: item.id).exists(notification_noticed_at: false)
        item = criteria.find_one_and_update({ '$set' => { notification_noticed_at: @now.utc } }, return_document: :after)
        if !item
          Rails.logger.info("#{item.name}: 通知を送信済みです")
          next
        end
      end

      if !@options[:unanswered_only] && item.notification_notice_state != 'enabled'
        Rails.logger.info("#{item.name}: 通知が有効ではありません")
        return
      end

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
    recipients = load_recipients(item)
    recipients = recipients.select{|recipient| recipient.id != @cur_user_id && recipient.use_notice?(item)}
    if recipients.blank?
      Rails.logger.info("#{item.name}: 通知対象ユーザーが見つかりません")
      return
    end

    path = Rails.application.routes.url_helpers.edit_gws_survey_readable_file_path(
      protocol: site.canonical_scheme, host: site.canonical_domain,
      site: site, folder_id: '-', category_id: '-', readable_id: item
    )

    i18n_key = Gws::Survey::Form.model_name.i18n_key
    subject = I18n.t("gws_notification.#{i18n_key}.subject", name: item.name, default: item.name)
    text = ApplicationController.helpers.sanitize(item.description.presence || '', tags: [])
    text = text.truncate(60)
    text = I18n.t("gws_notification.#{i18n_key}.text", name: item.name, text: text, path: path, default: path)

    message = Gws::Memo::Notice.new
    message.cur_site = site
    message.cur_user = user
    message.member_ids = recipients.pluck(:id)
    message.send_date = @now
    message.subject = subject
    message.format = 'text'
    message.text = text

    message.save!

    Gws::Memo::Mailer.notice_mail(message, recipients, item).try(:deliver_now)

    Rails.logger.info("#{item.name}: 通知送信")
  end

  def load_recipients(item)
    criteria = item.overall_readers.site(@cur_site || site)

    if @options[:unanswered_only]
      answered_user_ids = item.answered_users.pluck(:id)
      criteria = criteria.where("$and" => [{ id: { "$nin" => answered_user_ids } }])
    end

    criteria.active
  end
end
