class Gws::Board::NotificationJob < Gws::ApplicationJob
  def perform(*args)
    return unless site.notify_model?(Gws::Board::Topic)

    @now = Time.zone.now
    @options = args.extract_options!.with_indifferent_access
    @ids = args
    @cur_user_id = @options[:cur_user_id]
    select_items
    send_all_notifications
  end

  private

  def select_items
    criteria = Gws::Board::Topic.site(site).without_deleted.and_public(@now).topic
    criteria = criteria.where(notify_state: 'enabled')
    criteria = criteria.exists(notification_noticed_at: false)
    criteria = criteria.in(id: @ids) if @ids.present?

    @items = criteria
  end

  def send_all_notifications
    Rails.logger.info("#{@items.count.to_s(:delimited)}件の掲示板があります。")

    each_item do |item|
      if item.notification_noticed_at.present?
        Rails.logger.info("#{item.name}: 通知を送信済みです")
        next
      end

      criteria = Gws::Board::Topic.site(site).where(id: item.id).exists(notification_noticed_at: false)
      result = criteria.find_one_and_update({ '$set' => { notification_noticed_at: @now.utc } }, return_document: :after)
      if !result
        Rails.logger.info("#{item.name}: 通知を送信済みです")
        next
      end

      item = result
      if item.notify_state != 'enabled'
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
    recipients = item.subscribed_users
    recipients = recipients.select { |recipient| recipient.id != @cur_user_id && recipient.use_notice?(item) }
    if recipients.blank?
      Rails.logger.info("#{item.name}: 通知対象ユーザーが見つかりません")
      return
    end

    path = Rails.application.routes.url_helpers.gws_board_topic_path(site: site, mode: '-', category: '-', id: item)

    i18n_key = Gws::Board::Topic.model_name.i18n_key
    subject = I18n.t("gws_notification.#{i18n_key}.subject", name: item.name, default: nil)
    subject ||= item.name

    message = SS::Notification.new
    message.cur_group = site
    message.cur_user = user
    message.member_ids = recipients.pluck(:id)
    message.send_date = @now
    message.subject = subject
    message.format = 'text'
    message.url = path

    message.save!

    mail = Gws::Memo::Mailer.notice_mail(message, recipients, item)
    mail.deliver_now if mail

    Rails.logger.info("#{item.name}: 通知送信")
  end
end
