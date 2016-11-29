require "net/imap"
require "mail"
class Webmail::Mail
  include SS::Document
  include SS::Reference::User

  # Webmail::Imap
  cattr_accessor :imap

  attr_accessor :sync

  attr_accessor :rfc822, :text, :html, :attachments

  field :host, type: String
  field :account, type: String
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

  validates :host, presence: true
  validates :account, presence: true
  validates :mailbox, presence: true
  validates :uid, presence: true

  permit_params :text, :html

  before_destroy :imap_delete, if: ->{ imap.present? && @sync }

  default_scope -> { order_by date: -1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :subject, :text, :html if params[:keyword].present?
    criteria
  }

  def allowed?(action, user, opts = {})
    true
  end

  def imap
    self.class.imap
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

  def set_deleted
    imap.select(mailbox)
    set_flags(['Deleted'])
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

  def sanitized_html
    html = self.html
    html.gsub!(/<img [^>]*?>/i) do |img|
      img.sub(/ src="cid:.*?"/i) do |src|
        cid = src.sub(/.*?cid:(.*?)".*/i, '<\\1>')
        attachments.each do |file|
          if cid == file.content_id
            type = file.content_type.sub(/;.*/, '')
            src = %( data-src="data:#{type};base64,#{Base64.strict_encode64(file.read)}")
            break
          end
        end
        src
      end
    end

    ApplicationController.helpers.sanitize_with(html, attributes: %w(data-src))
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

    self.text = mail.text_part.decoded.toutf8 if mail.text_part
    self.html = mail.html_part.decoded.toutf8 if mail.html_part
    self.attachments = mail.attachments
  end

  private
    def imap_delete
      set_deleted
      imap.conn.expunge
    rescue Net::IMAP::NoResponseError => e
      rescue_imap_error(e)
    end

    def rescue_imap_error(e)
      errors.add :base, e.to_s
      return false
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

    def cache_key
      imap.cache_key.merge(mailbox: mailbox)
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

      imap.examine(mailbox)
      uids = imap.conn.uid_sort(sort_value, search_value, 'UTF-8')
      size = uids.size
      uids = uids.slice(offset, limit) || []

      items = cache_all(uids)
      items = items.sort { |a, b| b.date <=> a.date }

      Kaminari.paginate_array(items, total_count: size).page(page).per(limit)
    end

    def imap_find(uid)
      imap.examine(mailbox)

      item = cache_all([uid]).first
      item.fetch_body
      item
    end

    private
      def cache_all(uids)
        items = Mongoid::Criteria.new(self).where(cache_key).in(uid: uids).map do |item|
          item.flags = imap.conn.uid_fetch(item.uid, ['FLAGS'])[0].attr['FLAGS'].map(&:to_s)
          item.save if item.changed?
          uids.delete(item.uid)
          item
        end

        uids.each do |uid|
          # ALL - FLAGS INTERNALDATE RFC822.SIZE ENVELOPE
          msg = imap.conn.uid_fetch(uid, %w(ALL UID RFC822))[0]

          item = self.new(cache_key)
          item.uid = uid
          item.parse_message(msg)
          item.save
          items << item
        end

        items
      end
  end
end
