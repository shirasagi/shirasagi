require "net/imap"
require "mail"
class Webmail::Mail
  include SS::Document
  include SS::Reference::User
  include SS::FreePermission
  include Webmail::ImapAccessor
  include Webmail::Mail::Fields
  include Webmail::Mail::Parser
  include Webmail::Mail::Updater
  include Webmail::Mail::Message
  include Webmail::Addon::MailBody
  include Webmail::Addon::MailFile

  #index({ host: 1, account: 1, mailbox: 1, uid: 1 }, { unique: true })

  attr_accessor :flags, :text, :html, :attachments, :format,
                :reply_uid, :forward_uid, :signature,
                :to_text, :cc_text, :bcc_text

  field :host, type: String
  field :account, type: String
  field :mailbox, type: String
  field :uid, type: Integer
  field :internal_date, type: DateTime
  field :size, type: Integer

  ## header
  field :message_id, type: String
  field :date, type: DateTime
  field :sender, type: String
  field :from, type: Array, default: []
  field :to, type: Array, default: []
  field :cc, type: Array, default: []
  field :bcc, type: Array, default: []
  field :reply_to, type: Array, default: []
  field :in_reply_to, type: String
  field :references, type: SS::Extensions::Words
  field :content_type, type: String
  field :subject, type: String
  field :has_attachment, type: Boolean

  permit_params :reply_uid, :forward_uid, :in_reply_to, :references,
                :subject, :text, :html, :format,
                :to_text, :cc_text, :bcc_text,
                to: [], cc: [], bcc: [], reply_to: []

  validates :host, presence: true, uniqueness: { scope: [:account, :mailbox, :uid] }
  validates :account, presence: true
  validates :mailbox, presence: true
  validates :uid, presence: true
  validates :internal_date, presence: true

  default_scope -> { order_by internal_date: -1 }

  scope :imap_setting, ->(setting) {
    conf = setting.imap_settings
    where host: conf[:host], account: conf[:account]
  }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :subject, :text, :html if params[:keyword].present?
    criteria
  }

  def format_options
    %w(text html).map { |c| [c.upcase, c] }
  end

  def signature_options
    Webmail::Signature.user(cur_user).map do |c|
      [c.name, c.text]
    end
  end

  def replied_mail
    return nil if reply_uid.blank?
    @replied_mail ||= imap.mails.find(reply_uid)
  end

  def forwarded_mail
    return nil if forward_uid.blank?
    @forwarded_mail ||= imap.mails.find(forward_uid)
  end

  def validate_message(msg)
    errors.add :to, :blank if msg.to.blank?
    errors.blank?
  end

  def save_draft
    msg = Webmail::Mailer.new_message(self)
    imap.conn.append(imap.draft_box, msg.to_s, [:Draft], Time.zone.now)
    true
  end

  def send_mail
    msg = Webmail::Mailer.new_message(self)
    return false unless validate_message(msg)

    msg = msg.deliver_now.to_s
    replied_mail.set_answered if replied_mail
    imap.conn.append(imap.sent_box, msg.to_s, [:Seen], Time.zone.now)
    true
  end
end
