require "net/imap"
class Webmail::Quota
  include SS::Document
  #include SS::Reference::User

  field :host, type: String
  field :account, type: String
  field :mailbox, type: String
  field :quota, type: Integer, default: 0
  field :usage, type: Integer, default: 0
  field :reloaded, type: DateTime
  field :threshold_mb, type: Integer

  validates :host, presence: true, uniqueness: { scope: [:account, :mailbox] }
  validates :account, presence: true
  validates :mailbox, presence: true
  validates :quota, presence: true
  validates :usage, presence: true
  validates :reloaded, presence: true

  def quota?
    quota > 0
  end

  def quota_bytes
    quota * 1024
  end

  def usage_bytes
    usage * 1024
  end

  def usable_bytes
    quota_bytes - usage_bytes
  end

  def over_threshold?
    return false unless threshold_mb
    usage_mb = (usage_bytes.to_f / 1024 / 1024).round
    usage_mb >= threshold_mb
  end

  def label
    h = ApplicationController.helpers
    "#{h.number_to_human_size(usage_bytes)}/#{h.number_to_human_size(quota_bytes)}"
  end

  def threshold_label
    return "" unless over_threshold?
    h = ApplicationController.helpers
    h.t("webmail.notice.over_threshold", size: h.number_to_human_size(usable_bytes))
  end

  def percentage
    return 0 unless quota?
    (usage.to_f / quota.to_f) * 100
  end
end
