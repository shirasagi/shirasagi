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

  def label
    h = ApplicationController.helpers
    "#{h.number_to_human_size(usage_bytes)}/#{h.number_to_human_size(quota_bytes)}"
  end

  def percentage
    return 0 unless quota?
    (usage.to_f / quota.to_f) * 100
  end
end
