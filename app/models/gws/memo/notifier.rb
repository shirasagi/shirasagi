class Gws::Memo::Notifier
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_group, :cur_user, :to_users, :item

  class << self
    def deliver!(opts)
      new(opts).deliver!
    end

    def deliver(opts)
      new(opts).deliver
    end
  end

  def deliver!
    cur_user.cur_site ||= cur_group

    message = Gws::Memo::Message.new
    message.cur_site = cur_site
    message.cur_user = cur_user
    message.member_ids = to_users.pluck(:id) - [ cur_user.id ]
    message.from = { from_user.id.to_s => 'INBOX.Sent' }
    message.send_date = Time.zone.now

    set_subject(message)
    set_body(message)

    message.save!
  end

  def deliver
    deliver!
  rescue Mongoid::Errors::MongoidError => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  private

  def item_title
    item.try(:topic).try(:name) || item.try(:schedule).try(:name) || item.try(:_parent).try(:name) || item.try(:name)
  end

  def from_user
    @from_user ||= begin
      user = cur_site.sender_user
      user ||= cur_user
      user
    end
  end

  def i18n_key
    @i18n_key ||= item.class.model_name.i18n_key
  end

  def set_subject(mesasge)
    mesasge.subject = I18n.t("gws_notification.#{i18n_key}.subject", name: item_title, default: nil)
  end

  def set_body(mesasge)
    text = item.try(:text)
    text ||= begin
      html = item.try(:html).presence
      ApplicationController.helpers.sanitize(html, tags: []) if html
    end
    text = text.truncate(60) if text

    body = I18n.t("gws_notification.#{i18n_key}.text", name: item_title, text: text, default: nil)
    if body
      mesasge.format = 'text'
      mesasge.text = body
    end
  end
end
