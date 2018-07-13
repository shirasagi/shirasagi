module Gws::Questionnaire::Notification
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :notification_notice_state, type: String
    field :notification_noticed_at, type: DateTime

    permit_params :notification_notice_state

    before_validation :clear_notification_noticed_at, if: ->{ state_was != state }
    validates :notification_notice_state, presence: true, inclusion: { in: %w(enabled disabled), allow_blank: true }

    after_save :send_notification, if: -> { state_was != state && state == "public" }
  end

  def notification_notice_state_options
    %w(enabled disabled).map do |v|
      [ I18n.t("gws.options.notification.#{v}"), v ]
    end
  end

  private

  def clear_notification_noticed_at
    self.notification_noticed_at = nil
  end

  def send_notification
    return if state != "public"
    return if public?

    Gws::Questionnaire::NotificationJob.bind(site_id: site.id).perform_now(id)
  end
end
