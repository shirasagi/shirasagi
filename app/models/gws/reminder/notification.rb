class Gws::Reminder::Notification
  include SS::Document

  field :notify_at, type: DateTime
  field :delivered_at, type: DateTime

  field :state, type: String
  field :interval, type: Integer
  field :interval_type, type: String
  field :base_time, type: String

  embedded_in :reminder, inverse_of: :notifications

  validates :notify_at, presence: true

  def interval_label
    label = []
    label << I18n.t("gws/reminder.options.base_time")[base_time.to_sym] if base_time
    label << "#{interval}#{I18n.t("gws/reminder.options.interval_type")[interval_type.to_sym]}"
    label.join(" ")
  end
end
