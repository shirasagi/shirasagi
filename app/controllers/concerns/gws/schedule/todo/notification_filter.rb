module Gws::Schedule::Todo::NotificationFilter
  extend ActiveSupport::Concern
  include Gws::Memo::NotificationFilter

  included do
    self.destroy_notification_actions = [:soft_delete]
    self.destroy_all_notification_actions = [:soft_delete_all]
    after_action :send_finish_notification, only: [:finish]
    after_action :send_revert_notification, only: [:revert]
    after_action :send_finish_all_notification, only: [:finish_all]
    after_action :send_revert_all_notification, only: [:revert_all]
  end

  private

  def send_finish_notification
    if @item.in_discussion_forum
      url = url_for(action: 'show', id: @item, only_path: true)
    else
      url = url_for(action: 'show', category: Gws::Schedule::TodoCategory::ALL.id, id: @item, only_path: true)
    end
    i18n_key = @item.class.model_name.i18n_key
    subject = I18n.t("gws_notification.#{i18n_key}/finish.subject", name: @item.name)
    text = I18n.t("gws_notification.#{i18n_key}/finish.text", text: url)
    send_update_notification(subject, text)
  end

  def send_revert_notification
    if @item.in_discussion_forum
      url = url_for(action: 'show', id: @item, only_path: true)
    else
      url = url_for(action: 'show', category: Gws::Schedule::TodoCategory::ALL.id, id: @item, only_path: true)
    end
    i18n_key = @item.class.model_name.i18n_key
    subject = I18n.t("gws_notification.#{i18n_key}/revert.subject", name: @item.name)
    text = I18n.t("gws_notification.#{i18n_key}/revert.text", text: url)
    send_update_notification(subject, text)
  end

  def send_finish_all_notification
    return if @processed_items.blank?

    save = @item
    @processed_items.each do |item|
      @item = item
      send_finish_notification
    end
    @item = save
  end

  def send_revert_all_notification
    return if @processed_items.blank?

    save = @item
    @processed_items.each do |item|
      @item = item
      send_revert_notification
    end
    @item = save
  end
end
