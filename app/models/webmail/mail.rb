require "net/imap"
require "mail"
class Webmail::Mail
  include SS::Document
  include SS::Reference::User
  include SS::FreePermission
  include Webmail::ImapConnection
  include Webmail::Mail::Fields
  include Webmail::Mail::Parser
  include Webmail::Mail::Uids
  include Webmail::Mail::Updater
  include Webmail::Mail::Search
  include Webmail::Mail::Message
  include Webmail::Addon::MailBody
  include Webmail::Addon::MailFile

  #index({ host: 1, account: 1, mailbox: 1, uid: 1 }, { unique: true })

  attr_accessor :sync, :flags, :text, :html, :attachments, :format,
                :reply_uid, :forward_uid, :signature,
                :to_text, :cc_text, :bcc_text, :references

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
  field :references, type: Array, default: []
  field :content_type, type: String
  field :subject, type: String
  field :has_attachment, type: Boolean

  permit_params :reply_uid, :forward_uid,
                :subject, :text, :html, :format,
                :to_text, :cc_text, :bcc_text, :in_reply_to,
                to: [], cc: [], bcc: [], reply_to: [], references: []

  validates :host, presence: true
  validates :account, presence: true
  validates :mailbox, presence: true
  validates :uid, presence: true, uniqueness: { scope: [:host, :account, :mailbox] }
  validates :internal_date, presence: true

  before_destroy :imap_delete, if: ->{ @sync && imap.present? }

  default_scope -> { order_by internal_date: -1 }

  scope :user, ->(user) {
    conf = user.imap_settings
    where host: conf[:host], account: conf[:account]
  }

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
    Webmail::Signature.user(cur_user).map do |c|
      [c.name, c.text]
    end
  end

  def replied_mail
    return nil if reply_uid.blank?
    return @replied_mail if @replied_mail
    @replied_mail = self.class.imap_find(reply_uid)
  end

  def forwarded_mail
    return nil if forward_uid.blank?
    return @forwarded_mail if @forwarded_mail
    @forwarded_mail = self.class.imap_find(reply_uid)
  end

  def save_draft
    msg = Webmail::Mailer.new_message(self)
    imap.conn.append(imap.user.imap_draft_box, msg.to_s, [:Draft], Time.zone.now)
    true
  end

  def validate_message(msg)
    errors.add :to, :blank if msg.to.blank?
    errors.blank?
  end

  def send_mail
    msg = Webmail::Mailer.new_message(self)
    return false unless validate_message(msg)

    msg = msg.deliver_now.to_s
    replied_mail.set_answered if replied_mail
    imap.conn.append(imap.user.imap_sent_box, msg.to_s, [:Seen], Time.zone.now)
    true
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
    def mailbox_attributes
      imap.account_attributes.merge(mailbox: mailbox)
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
      scope  = where({})
      page   = scope.current_page
      limit  = scope.limit_value
      offset = scope.offset_value

      uids = imap.conn.uid_sort(sort_keys, search_keys, 'UTF-8')
      size = uids.size
      uids = uids.slice(offset, limit) || []

      items = {}
      uids.each { |uid| items[uid] = nil }

      uids = cache_all(uids, items) if uids.present? && SS.config.webmail.cache_mails
      uids = fetch_all(uids, items) if uids.present?

      Kaminari.paginate_array(items.values, total_count: size).page(page).per(limit)
    end

    def imap_find(uid, *division)
      uid = uid.to_i

      attr = %w(FAST RFC822.HEADER) # FAST: FLAGS INTERNALDATE RFC822.SIZE
      attr += %w(BODYSTRUCTURE) if division.include?(:body)
      attr << 'RFC822' if division.include?(:rfc822)

      resp = imap.conn.uid_fetch(uid, attr)
      raise Mongoid::Errors::DocumentNotFound.new(Webmail::Imap, uid: uid) unless resp

      item = self.new(mailbox_attributes)
      item.parse(resp[0])
      item.fetch_body if division.include?(:body)
      item
    end

    def find_part(uid, section)
      uid = uid.to_i

      resp = imap.conn.uid_fetch(uid, ['BODYSTRUCTURE', "BODY[#{section}.TEXT]"])
      raise Mongoid::Errors::DocumentNotFound.new(Webmail::Imap, uid: uid) unless resp

      item = self.new(mailbox_attributes)
      item.body_structure = resp[0].attr['BODYSTRUCTURE']

      part = item.all_parts[section]
      raise Mongoid::Errors::DocumentNotFound.new(Webmail::Imap, uid: uid) unless part

      Webmail::MailPart.new(part, section, resp[0].attr["BODY[#{section}.TEXT]"])
    end

    private
      def cache_all(uids, ref_items)
        items = Mongoid::Criteria.new(self).where(mailbox_attributes).in(uid: uids)
        item_uids = items.map(&:uid)

        flags = []

        if items.present?
          resp = imap.conn.uid_fetch(item_uids, ['FLAGS']) || []
          resp.each do |data|
            flags[data.attr['UID']] = data.attr['FLAGS'] || []
          end
        end

        items.each do |item|
          next if ref_items[item.uid]
          item.flags = flags[item.uid]
          ref_items[item.uid] = item
        end

        uids - item_uids
      end

      def fetch_all(uids, ref_items)
        resp = imap.conn.uid_fetch(uids, %w(FAST RFC822.HEADER)) || []
        resp.each do |data|
          uid = data.attr['UID']
          uids.delete(uid)

          item = self.new(mailbox_attributes)
          ref_items[uid] = item

          begin
            item.parse(data)
            item.save if SS.config.webmail.cache_mails
          rescue => e
            raise e if Rails.env.development?
            item.subject = "[Error] #{e}"
          end
        end

        uids
      end
  end
end
