class Gws::Reminder::Notification
  include SS::Document

  attr_accessor :in_notify_before
  field :notify_at, type: DateTime
  field :delivered_at, type: DateTime

  embedded_in :reminder, inverse_of: :notifications

  validates :notify_at, presence: true

  before_validation :set_notify_at

  def notify_before
    return -1 if reminder.date.blank?
    return -1 if notify_at.blank?

    return -1 if notify_at.to_i == 0
    ((reminder.date - notify_at) * 24 * 60).to_i
  end

  private
    def set_notify_at
      return if in_notify_before.blank?
      return if reminder.date.blank?
      self.in_notify_before = in_notify_before.to_i unless in_notify_before.is_a?(Fixnum)

      if self.in_notify_before < 0
        # disable notification by setting EPOCH
        self.notify_at = Time.zone.at(0)
      else
        # enable notification
        self.notify_at = reminder.date - in_notify_before.minutes
        self.delivered_at = Time.zone.at(0)
      end
    end
end
