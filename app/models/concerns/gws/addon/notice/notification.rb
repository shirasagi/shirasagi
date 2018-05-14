module Gws::Addon::Notice::Notification
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :message_notification, type: String
    field :email_notification, type: String
    field :notification_noticed, type: DateTime
    permit_params :message_notification, :email_notification, :notification_noticed
    validates :message_notification, inclusion: { in: %w(disabled enabled), allow_blank: true }
    validates :email_notification, inclusion: { in: %w(disabled enabled), allow_blank: true }
  end

  def message_notification_options
    %w(disabled enabled).map do |v|
      [I18n.t("gws.options.notification.#{v}"), v]
    end
  end

  alias email_notification_options message_notification_options
end
