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

  validates :host, presence: true
  validates :account, presence: true
  validates :original_name, presence: true, uniqueness: { scope: [:host, :account] }
  validates :name, presence: true

  before_validation :validate_name, if: ->{ @sync && name_changed? }

  default_scope -> { order_by order: 1, downcase_name: 1 }

  scope :and_imap, ->(imap) {
    where imap.account_scope
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
      name = dir + name.sub(/^#{::Regexp.escape(src)}(\.|$)/, dst + '\\1')
    end
    name
  end

  def inbox?
    original_name =~ /^INBOX(\.|$)/
  end

  def special_mailbox?
    imap.special_mailboxes.find { |m| original_name =~ /^#{m}(\.|$)/ }.present?
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
  def parse_mailbox_list(box)
    self.name = Net::IMAP.decode_utf7(box.name)
    self.original_name = box.name
    self.delim = box.delim
    self.attr = box.attr.map(&:to_s) || []
    self.depth = original_name.split(box.delim).size
    self.depth = self.depth - 1 if self.depth.nonzero?
  end

  def imap_create
    return false if imap.blank?
    imap.conn.create original_name
  rescue Net::IMAP::NoResponseError => e
    rescue_imap_error(e)
  end

  def imap_update
    return false if imap.blank?
    imap.conn.rename original_name_was, original_name
    items = Webmail::Mail.where(imap.account_scope).where(mailbox: name_was)
    items.each(&:destroy_rfc822)
    items.delete_all
  rescue Net::IMAP::NoResponseError => e
    rescue_imap_error(e)
  end

  def imap_delete
    return false if imap.blank?
    imap.conn.delete original_name
    items = mails
    items.each(&:destroy_rfc822)
    items.delete_all
  rescue Net::IMAP::NoResponseError => e
    rescue_imap_error(e)
  end

  private

  def validate_name
    self.name = self.name.tr('/', '.')
    #self.name = "INBOX.#{name}" unless self.name =~ /^INBOX\./
    self.original_name = Net::IMAP.encode_utf7(name)
    self.delim = '.'
    self.attr = []
    self.depth = self.name.split('.').size
    self.depth = self.depth - 1 if self.depth.nonzero?
  end

  def rescue_imap_error(exception)
    errors.add :base, exception.to_s
    return false
  end
end
