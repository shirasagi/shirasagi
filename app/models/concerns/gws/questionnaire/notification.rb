module Gws::Questionnaire::Notification
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :notification_notice_state, type: String
    field :notification_notice_at, type: DateTime

    permit_params :notification_notice_state

    before_validation :clear_notification_notice_at, if: ->{ state_was != state }
    validates :notification_notice_state, presence: true, inclusion: { in: %w(enabled disabled), allow_blank: true }
  end

  def notification_notice_state_options
    %w(enabled disabled).map do |v|
      [ I18n.t("gws.options.notification.#{v}"), v ]
    end
  end

  private

  def clear_notification_notice_at
    self.notification_notice_at = nil
  end
end
