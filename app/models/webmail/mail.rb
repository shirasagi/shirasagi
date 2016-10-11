require "net/imap"
require "mail"
class Webmail::Mail
  include SS::Document
  include SS::Reference::User

  attr_accessor :imap, :conf, :text, :html

  field :uid, type: Integer
  field :message_id, type: String
  field :size, type: Integer
  field :date, type: DateTime
  field :flags, type: Array
  field :from, type: String
  field :sender, type: String
  field :to, type: Array
  field :cc, type: Array
  field :bcc, type: Array
  field :reply_to, type: Array
  field :in_reply_to, type: Array
  field :subject, type: String
  #field :text, type: String
  #field :html, type: String
  field :attachments, type: Array

  permit_params :text, :html

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :subject, :text, :html if params[:keyword].present?
    criteria
  }

  def seen?
    flags.include?(:Seen)
  end

  def unseen?
    !seen?
  end

  def set_seen
    imap.uid_store(uid, '+FLAGS', [:Seen])
  end

  def allowed?(action, user, opts = {})
    true
  end

  class << self
    def build_addresses(addresses)
      return [] unless addresses
      addresses.map do |addr|
        if addr.name.present?
          "#{addr.name.toutf8} <#{addr.mailbox}@#{addr.host}>"
        else
          "#{addr.mailbox}@#{addr.host}"
        end
      end
    end

    def new_message(msg, attributes = {})
      envelope = msg.attr["ENVELOPE"]

      mail = ::Mail.read_from_string msg.attr['RFC822']
      text = nil
      html = nil

      if mail.body.multipart?
        mail.body.parts.each do |part|
          text ||= part.decoded.toutf8 if part.content_type.start_with?('text/plain')
          html ||= part.decoded.toutf8 if part.content_type.start_with?('text/html')
        end
      else
        text = mail.body.decoded.toutf8
      end

      item = self.new({
        uid: msg.attr["UID"],
        message_id: envelope.message_id,
        size: msg.attr['RFC822.SIZE'],
        flags: msg.attr['FLAGS'],
        date: envelope.date,
        from: build_addresses(envelope.from)[0],
        sender: build_addresses(envelope.sender)[0],
        to: build_addresses(envelope.to),
        cc: build_addresses(envelope.cc),
        bcc: build_addresses(envelope.bcc),
        reply_to: build_addresses(envelope.reply_to),
        in_reply_to: build_addresses(envelope.in_reply_to),
        subject: envelope.subject.toutf8,
        text: text,
        html: html,
        attachments: mail.attachments
      })
      item.attributes = attributes
      item
    end

    def allowed?(action, user, opts = {})
      true
    end
  end
end
