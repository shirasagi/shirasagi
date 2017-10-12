require "net/imap"
class Webmail::Mailbox
  include SS::Document
  include SS::Reference::User
  include SS::FreePermission
  include Webmail::ImapAccessor

  attr_accessor :sync, :messages, :recent

  field :host, type: String
  field :account, type: String
  field :original_name, type: String
  field :name, type: String
  field :delim, type: String
  field :attr, type: Array, default: []
  field :order, type: Integer, default: 0
  field :depth, type: Integer
  field :unseen, type: Integer, default: 0
  field :uidnext, type: Integer, default: 0

  permit_params :name

  validates :host, presence: true, uniqueness: { scope: [:account, :original_name] }
  validates :account, presence: true
  validates :original_name, presence: true
  validates :name, presence: true

  before_validation :validate_name, if: ->{ @sync && name_changed? }
  before_create :imap_create, if: ->{ @sync && imap.present? }
  before_update :imap_update, if: ->{ @sync && imap.present? }
  before_destroy :imap_delete, if: ->{ @sync && imap.present? }

  default_scope -> { order_by order: 1, downcase_name: 1 }

  scope :imap_setting, ->(setting) {
    conf = setting.imap_settings
    where host: conf[:host], account: conf[:account]
  }

  def sync(sync = true)
    @sync = sync
    self
  end

  def noselect?
    attr.include?('Noselect')
  end

  def basename
    locale_name.sub(/.*\./, '')
  end

  def locale_name
    list = [
      [imap.sent_box, I18n.t('webmail.box.sent')],
      [imap.draft_box, I18n.t('webmail.box.draft')],
      [imap.trash_box, I18n.t('webmail.box.trash')],
      ['INBOX', I18n.t('webmail.box.inbox')],
    ]
    name = self.name
    list.each do |src, dst|
      next unless name =~ /^#{src}(\.|$)/
      dir = src.include?('.') ? src.sub(/[^.]+$/, '') : ''
      name = dir + name.sub(/^#{Regexp.escape(src)}(\.|$)/, dst + '\\1')
    end
    name
  end

  def status
    return self if noselect?

    begin
      # STAUS: MESSAGES,RECENT,UIDNEXT,UIDVALIDITY,UNSEEN
      status = imap.conn.status(original_name, %w(MESSAGES RECENT UIDNEXT UNSEEN))
      self.messages = status['MESSAGES']
      self.recent = status['RECENT']
      self.uidnext = status['UIDNEXT']
      self.unseen = status['UNSEEN']
    rescue Net::IMAP::NoResponseError
      self.unseen = 0
    end
    self
  end

  def icon
    return '&#xE163;' if original_name == imap.sent_box # send
    return '&#xE254;' if original_name == imap.draft_box # mode_edit
    return '&#xE872;' if original_name == imap.trash_box # delete
    return '&#xE2C7;' if noselect? # folder
    '&#xE2C8;' # folder_open
  end

  def css_class
    list = [original_name.gsub(/[^\w]/, '-').downcase]
    list << 'mailbox--noselect' if noselect?
    list.join(' ')
  end

  def mails
    Webmail::Mail.where(imap.account_scope).where(mailbox: name)
  end

  # @param [Net::IMAP::MailboxList] ml
  def parse_mailbox_list(ml)
    self.name = Net::IMAP.decode_utf7(ml.name)
    self.original_name = ml.name
    self.delim = ml.delim
    self.attr = ml.attr.map(&:to_s) || []
    self.depth = original_name.split(ml.delim).size - 1
  end

  private

  def validate_name
    self.name = self.name.tr('/', '.')
    self.name = "INBOX.#{name}" unless self.name =~ /^INBOX\./
    self.original_name = Net::IMAP.encode_utf7(name)
    self.delim = '.'
    self.attr = []
    self.depth = self.name.split('.').size - 1
  end

  def imap_create
    imap.conn.create original_name
  rescue Net::IMAP::NoResponseError => e
    rescue_imap_error(e)
  end

  def imap_update
    imap.conn.rename original_name_was, original_name
    Webmail::Mail.where(imap.account_scope).where(mailbox: name_was).delete_all
  rescue Net::IMAP::NoResponseError => e
    rescue_imap_error(e)
  end

  def imap_delete
    imap.conn.delete original_name
    mails.delete_all
  rescue Net::IMAP::NoResponseError => e
    rescue_imap_error(e)
  end

  def rescue_imap_error(e)
    errors.add :base, e.to_s
    return false
  end
end
