module Gws::Schedule::Todo::NotificationFilter
  extend ActiveSupport::Concern
  include Gws::Memo::NotificationFilter

  included do
    after_action :send_finish_notification, only: [:finish]
    after_action :send_revert_notification, only: [:revert]
  end

  private

  def send_finish_notification
    url = Rails.application.routes.url_helpers.gws_schedule_todo_readable_path(id: @item.id, site: @cur_site.id, category: '-', mode: '-')
    i18n_key = @item.class.model_name.i18n_key
    subject = I18n.t("gws_notification.#{i18n_key}/finish.subject", name: @item.name)
    text = I18n.t("gws_notification.#{i18n_key}/finish.text", text: url)
    send_update_notification(subject, text)
  end

  def send_revert_notification
    url = Rails.application.routes.url_helpers.gws_schedule_todo_readable_path(id: @item.id, site: @cur_site.id, category: '-', mode: '-')
    i18n_key = @item.class.model_name.i18n_key
    subject = I18n.t("gws_notification.#{i18n_key}/revert.subject", name: @item.name)
    text = I18n.t("gws_notification.#{i18n_key}/revert.text", text: url)
    send_update_notification(subject, text)
  end
end
