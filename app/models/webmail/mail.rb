require "net/imap"
require "mail"
class Webmail::Mail
  include SS::Document
  include SS::Reference::User

  # Webmail::Imap
  cattr_accessor :imap

  attr_accessor :rfc822, :text, :html, :attachments

  field :host, type: String
  field :mailbox, type: String
  field :uid, type: Integer
  field :message_id, type: String
  field :size, type: Integer
  field :date, type: DateTime
  field :flags, type: Array, default: []
  field :from, type: String
  field :sender, type: String
  field :to, type: Array, default: []
  field :cc, type: Array, default: []
  field :bcc, type: Array, default: []
  field :reply_to, type: Array, default: []
  field :in_reply_to, type: Array, default: []
  field :subject, type: String
  field :attachments_count, type: Integer

  permit_params :text, :html

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :subject, :text, :html if params[:keyword].present?
    criteria
  }

  def allowed?(action, user, opts = {})
    true
  end

  def seen?
    flags.to_a.include?('Seen')
  end

  def unseen?
    !seen?
  end

  def star?
    flags.to_a.include?('Flagged')
  end

  def set_seen
    set_flags(['Seen'])
  end

  def unset_seen
    unset_flags(['Seen'])
  end

  def set_star
    set_flags(['Flagged'])
  end

  def unset_star
    unset_flags(['Flagged'])
  end

  def set_flags(values)
    self.flags ||= []
    self.flags = (self.flags + values).uniq
    self.save if changed?
    imap.conn.uid_store(uid, '+FLAGS', values.map(&:to_sym)) # required symbole
  end

  def unset_flags(values)
    self.flags ||= []
    self.flags -= values
    self.save if changed?
    imap.conn.uid_store(uid, '-FLAGS', values.map(&:to_sym)) # required symbole
  end

  def attachments?
    attachments_count > 0
  end

  def parse_message(msg)
    envelope = msg.attr["ENVELOPE"]
    mail = ::Mail.read_from_string msg.attr['RFC822']

    self.attributes = {
      uid: msg.attr["UID"],
      message_id: envelope.message_id,
      size: msg.attr['RFC822.SIZE'],
      flags: msg.attr['FLAGS'].map(&:to_s).presence,
      date: envelope.date,
      from: self.class.build_addresses(envelope.from)[0],
      sender: self.class.build_addresses(envelope.sender)[0],
      to: self.class.build_addresses(envelope.to).presence,
      cc: self.class.build_addresses(envelope.cc).presence,
      bcc: self.class.build_addresses(envelope.bcc).presence,
      reply_to: self.class.build_addresses(envelope.reply_to).presence,
      in_reply_to: self.class.build_addresses(envelope.in_reply_to).presence,
      subject: envelope.subject.toutf8,
      attachments_count: mail.attachments.size
    }
  end

  def fetch_body
    msg = imap.conn.uid_fetch(uid, ['RFC822'])[0]
    self.rfc822 = msg.attr['RFC822']
    mail = ::Mail.read_from_string(rfc822)

    if mail.body.multipart?
      mail.body.parts.each do |part|
        self.text ||= part.decoded.toutf8 if part.content_type.start_with?('text/plain')
        self.html ||= part.decoded.toutf8 if part.content_type.start_with?('text/html')
      end
    else
      self.text = mail.body.decoded.toutf8
    end

    self.attachments = mail.attachments
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

    def allowed?(action, user, opts = {})
      true
    end

    # Criteria: where(mailbox: String)
    def mailbox
      where({}).selector['mailbox'] || 'INBOX'
    end

    # Criteria: where(sort: Array)
    def sort_value
      where({}).selector['sort'] || %w(REVERSE DATE)
    end

    # Criteria: where(search: Array)
    def search_value
      where({}).selector['search'] || %w(UNDELETED)
    end

    def imap_all
      scope = where({})
      page = scope.current_page
      limit = scope.limit_value
      offset = scope.offset_value

      imap.conn.examine(mailbox)
      uids = imap.conn.uid_sort(sort_value, search_value, 'UTF-8')
      size = uids.size
      uids = uids.slice(offset, limit) || []

      items = uids.map { |uid| cache_find(uid) }

      Kaminari.paginate_array(items, total_count: size).page(page).per(limit)
    end

    def imap_find(uid)
      imap.conn.examine(mailbox)

      item = cache_find(uid)
      item.fetch_body
      item
    end

    private
      def cache_key(uid)
        { uid: uid, user_id: imap.user.id, mailbox: mailbox, host: imap.conf[:host] }
      end

      def cache_find(uid)
        cond = cache_key(uid)
        item = Mongoid::Criteria.new(self).where(cond).first

        if item
          # cache
          item.flags = imap.conn.uid_fetch(uid, ['FLAGS'])[0].attr['FLAGS'].map(&:to_s)
          item.save if item.changed?
        else
          # ALL - FLAGS INTERNALDATE RFC822.SIZE ENVELOPE
          msg = imap.conn.uid_fetch(uid, %w(ALL UID RFC822))[0]
          item = self.new(cond)
          item.parse_message(msg)
          item.save
        end

        item
      end
  end
end
