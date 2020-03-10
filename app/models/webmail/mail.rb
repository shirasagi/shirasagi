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
  index(internal_date: -1)
  index(host: 1, account: 1, mailbox: 1, uid: 1, internal_date: -1)

  attr_accessor :flags, :text, :html, :attachments, :format,
                :reply_uid, :forward_uid, :edit_as_new_uid, :signature,
                :to_text, :cc_text, :bcc_text,
                :in_request_mdn, :in_request_dsn, :all_export, :mail_ids

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
  field :disposition_notification_to, type: Array, default: []

  permit_params :reply_uid, :forward_uid, :in_reply_to, :references,
                :subject, :text, :html, :format,
                :to_text, :cc_text, :bcc_text,
                :in_request_mdn, :in_request_dsn,
                to: [], cc: [], bcc: [], reply_to: []

  validates :host, presence: true, uniqueness: { scope: [:account, :mailbox, :uid] }
  validates :account, presence: true
  validates :mailbox, presence: true
  validates :uid, presence: true
  validates :internal_date, presence: true

  default_scope -> { order_by internal_date: -1 }

  scope :and_imap, ->(imap) {
    where imap.account_scope
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

  def replied_mail
    return nil if reply_uid.blank?
    @replied_mail ||= imap.mails.find(reply_uid)
  end

  def forwarded_mail
    return nil if forward_uid.blank?
    @forwarded_mail ||= imap.mails.find(forward_uid)
  end

  def validate_message(msg)
    if msg.to.blank?
      errors.add :to, :blank
      return errors.blank?
    end

    validate_email_address(msg, :to)
    validate_email_address(msg, :cc)
    validate_email_address(msg, :bcc)
    validate_email_size
    errors.blank?
  end

  def validate_email_address(msg, field)
    emails = msg.send(field)
    return errors.blank? if emails.blank?

    begin
      emails = emails.map { |to| Webmail::Converter.extract_address(to) }
      emails.each { |email| raise "invalid address" unless email =~ EmailValidator::REGEXP }
    rescue => e
      errors.add field, :invalid_email_included
    end
    errors.blank?
  end

  def validate_email_size
    limit = SS.config.webmail.send_mail_size_limit

    return if size.to_i <= 0
    return if limit.to_i <= 0

    if limit.to_i < size.to_i
      message = I18n.t("errors.messages.too_large_mail_size", size: size.to_s(:human_size), limit: limit.to_s(:human_size))
      errors.add :base, message
    end
  end

  def save_draft
    msg = Webmail::Mailer.new_message(self)

    # save all headers
    msg.header.fields.each do |field|
      field.include_in_headers = true if field.respond_to?(:include_in_headers)
    end

    imap.select(imap.draft_box)
    imap.conn.append(imap.draft_box, msg.to_s, [:Draft, :Seen], Time.zone.now)
    if draft?
      imap.uids_delete([uid])
    end
    true
  end

  def send_mail
    msg = Webmail::Mailer.new_message(self)
    return false unless validate_message(msg)

    begin
      msg.deliver_now
    rescue Net::SMTPError => e
      errors.add :base, I18n.t("errors.messages.smtp_delivery_error", message: e.message)
      return false
    end

    replied_mail.set_answered if replied_mail

    # save all headers
    msg.header.fields.each do |field|
      field.include_in_headers = true if field.respond_to?(:include_in_headers)
    end

    imap.select(imap.sent_box)
    imap.conn.append(imap.sent_box, msg.to_s, [:Seen], Time.zone.now)
    if draft?
      imap.select(imap.draft_box)
      imap.uids_delete([uid])
    end

    true
  end

  def import_mail(msg, opts = {})
    date_time = opts[:date_time] || Time.zone.now

    imap.select('INBOX')
    imap.conn.append('INBOX', msg.to_s, [:Seen], date_time.in_time_zone)
  end

  def requested_mdn?
    return false if flags.include?(:"$MDNSent")
    return false if disposition_notification_to.blank?

    to.each do |mdn_to|
      mdn_to = Webmail::Converter.extract_address(mdn_to)
      return true if mdn_to == imap.address
    end
    return false
  end

  def send_mdn
    return false unless requested_mdn?

    msg = Webmail::Mailer.mdn_message(self)
    return false unless validate_message(msg)
    msg.deliver_now
    true
  end

  def rfc822_path
    separated_id = [4, 6, 22].map { |i| id.to_s.slice(i, 2) }.join("/")
    "#{Rails.root}/private/files/webmail_files/#{separated_id}/_/#{id}"
  end

  def save_rfc822
    return if rfc822.blank?

    dir = ::File.dirname(rfc822_path)
    Fs.mkdir_p(dir) unless Fs.exists?(dir)
    Fs.binwrite(rfc822_path, rfc822)
  end

  def read_rfc822
    self.rfc822 = Fs.exists?(rfc822_path) ? Fs.binread(rfc822_path) : nil
  end

  def destroy_rfc822
    Fs.rm_rf(rfc822_path) if Fs.exists?(rfc822_path)
  end
end
