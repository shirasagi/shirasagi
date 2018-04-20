module Gws::Schedule::Todo::NotificationFilter
  extend ActiveSupport::Concern
  include Gws::Memo::NotificationFilter

  included do
    after_action :send_finish_notification, only: [:finish]
    after_action :send_revert_notification, only: [:revert]
  end

  private

  def send_finish_notification
    i18n_key = @item.class.model_name.i18n_key
    subject = I18n.t("gws_notification.#{i18n_key}/finish.subject", name: @item.name)
    text = I18n.t("gws_notification.#{i18n_key}/finish.text", name: @item.name)
    send_update_notification(subject, text)
  end

  def send_revert_notification
    i18n_key = @item.class.model_name.i18n_key
    subject = I18n.t("gws_notification.#{i18n_key}/revert.subject", name: @item.name)
    text = I18n.t("gws_notification.#{i18n_key}/revert.text", name: @item.name)
    send_update_notification(subject, text)
  end
end
