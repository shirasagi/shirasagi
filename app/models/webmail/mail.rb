require "net/imap"
require "mail"
class Webmail::Mail
  include SS::Document
  include SS::Reference::User
  include SS::FreePermission
  include Webmail::ImapConnection
  include Webmail::Mail::Flag
  include Webmail::Mail::Parser
  include Webmail::Mail::Search
  include Webmail::Mail::MessageBuilder
  include Webmail::Addon::File

  #index({ uid: 1, user_id: 1, host: 1, account: 1, mailbox: 1 }, { unique: true })

  attr_accessor :sync, :rfc822, :text, :html, :attachments, :format, :reply_uid, :forward_uid, :signature,
                :to_text, :cc_text, :bcc_text

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
  field :in_reply_to, type: String
  field :references, type: Array, default: []
  field :subject, type: String
  field :attachments_count, type: Integer, default: 0

  permit_params :subject, :text, :html, :format, :reply_uid, :forward_uid,
                :to_text, :cc_text, :bcc_text,
                to: [], cc: [], bcc: [], reply_to: []

  validates :host, presence: true
  validates :account, presence: true
  validates :mailbox, presence: true
  validates :uid, presence: true

  before_destroy :imap_delete, if: ->{ imap.present? && @sync }

  default_scope -> { order_by date: -1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :subject, :text, :html if params[:keyword].present?
    criteria
  }

  def sync
    @sync = true
    self
  end

  def format_options
    %w(text html).map { |c| [c.upcase, c] }
  end

  def signature_options
    Webmail::Signature.user(user).map do |c|
      [c.name, c.text]
    end
  end

  def html?
    return format == 'html' if format.present?
    !html.nil?
  end

  def attachments?
    attachments_count > 0
  end

  def save_to_sent(msg)
    if reply_uid.present?
      ref = self.class.imap_find(reply_uid)
      ref.set_flags([:Answered])
    elsif forward_uid.present?
      #Forwarded
    end
    imap.conn.append(imap.user.imap_sent_box, msg, [:Seen], Time.zone.now)
  end

  def save_to_draft(msg)
    imap.conn.append(imap.user.imap_draft_box, msg, [:Draft], Time.zone.now)
  end

  private
    def imap_delete
      set_deleted
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

    def cache_key
      imap.cache_key.merge(mailbox: mailbox)
    end

    # Criteria: where(mailbox: String)
    def mailbox
      where({}).selector['mailbox'] || 'INBOX'
    end

    # Criteria: where(sort: Array)
    def sort_keys
      where({}).selector['sort'] || %w(REVERSE ARRIVAL)
    end

    # Criteria: where(search: Array)
    def search_keys
      where({}).selector['search'] || %w(ALL) # %w(UNDELETED)
    end

    def imap_all
      scope = where({})
      page = scope.current_page
      limit = scope.limit_value
      offset = scope.offset_value

      uids = imap.conn.uid_sort(sort_keys, search_keys, 'UTF-8')
      size = uids.size
      uids = uids.slice(offset, limit) || []

      items = cache_all(uids)
      items = items.sort { |a, b| (b.date || b.created) <=> (a.date || a.created) }

      Kaminari.paginate_array(items, total_count: size).page(page).per(limit)
    end

    def imap_find(uid)
      uid = uid.to_i
      msg = imap.conn.uid_fetch(uid, ['RFC822'])
      raise Mongoid::Errors::DocumentNotFound.new(Webmail::Imap, uid: uid) unless msg

      item = cache_all([uid]).first
      item.parse_body(msg[0])
      item
    end

    private
      def cache_all(uids)
        items = Mongoid::Criteria.new(self).where(cache_key).in(uid: uids)
        item_uids = items.map(&:uid)

        if items.present?
          flags = []

          messages = imap.conn.uid_fetch(item_uids, ['FLAGS']) || []
          messages.each do |msg|
            flags[msg.attr['UID']] = (msg.attr['FLAGS'] || []).map(&:to_s)
          end

          items.each do |item|
            item.set flags: flags[item.uid] if item.flags != flags[item.uid]
          end
        end

        uids = uids - item_uids
        return items if uids.blank?

        # ALL - FLAGS INTERNALDATE RFC822.SIZE ENVELOPE
        messages = imap.conn.uid_fetch(uids, %w(ALL RFC822)) || []
        messages.each do |msg|
          item = self.new(cache_key)
          items << item

          begin
            item.parse_message(msg)
            item.save
          rescue => e
            raise e if Rails.env.development?
            item.subject = "[Error] #{e}"
            def item.save; end
          end
        end

        items
      end
  end
end
