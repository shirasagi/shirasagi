module Gws::Memo::NotificationFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_destroyed_item, only: [:destroy, :soft_delete]
    before_action :set_destroyed_items, only: [:destroy_all, :soft_delete_all]

    after_action :send_update_notification, only: [:create, :update]
    after_action :send_destroy_notification, only: [:destroy, :destroy_all, :soft_delete, :soft_delete_all]
  end

  private

  def send_update_notification
    return if request.get?
    return if response.code !~ /^3/
    return unless @item.try(:notify_enabled?)

    users = @item.subscribed_users
    users = users.nin(id: @cur_user.id) if @cur_user

    return if users.blank?

    Gws::Memo::Notifier.deliver!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: users, item: @item
    )
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def send_destroy_notification
    return if request.get?
    return if response.code !~ /^3/
    return unless @item.try(:notify_enabled?)

    @destroyed_items ||= []
    @destroyed_items << @destroyed_item if @destroyed_item
    return if @destroyed_items.blank?

    @destroyed_items.each do |item, users|
      users = users.nin(id: @cur_user.id) if @cur_user
      next if users.blank?

      i18n_key = item.class.model_name.i18n_key
      subject = I18n.t("gws_notification.#{i18n_key}/destroy.subject", name: item.name)
      text = I18n.t("gws_notification.#{i18n_key}/destroy.text", name: item.name)

      Gws::Memo::Notifier.deliver!(
        cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
        to_users: users, item: item, subject: subject, text: text
      )
    end
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def set_destroyed_item
    return if request.get?

    if @item
      @destroyed_item = [@item.dup, @item.subscribed_users]
    end
  end

  def set_destroyed_items
    return if request.get?

    if @items.present?
      @destroyed_items ||= []
      @items.each do |item|
        @destroyed_items << [item.dup, users]
      end
    end
  end
end
