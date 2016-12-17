require "net/imap"
class Webmail::Mailbox
  include SS::Document
  include SS::Reference::User
  include SS::FreePermission

  attr_accessor :sync, :messages, :unseen

  field :host, type: String
  field :account, type: String
  field :name, type: String
  field :downcase_name, type: String
  field :order, type: Integer, default: 0
  field :depth, type: Integer

  permit_params :name

  validates :host, presence: true
  validates :account, presence: true
  validates :name, presence: true
  validates :downcase_name, presence: true

  before_validation :validate_name, if: ->{ name.present? }
  before_create :imap_create, if: ->{ imap.present? && @sync }
  before_update :imap_update, if: ->{ imap.present? && @sync }
  before_destroy :imap_delete, if: ->{ imap.present? && @sync }

  default_scope -> { order_by order: 1, downcase_name: 1 }

  def imap
    self.class.imap
  end

  def stat
    status = imap.conn.status(original_name, %w(MESSAGES UNSEEN))
    self.messages = status['MESSAGES']
    self.unseen = status['UNSEEN']
  rescue Net::IMAP::NoResponseError
    self.unseen = -1
  end

  def basename
    name.sub(/.*\./, '')
  end

  def short_name
    name.sub(/^INBOX\./, '')
  end

  def original_name(name = self.name)
    Net::IMAP.encode_utf7(name)
  end

  def css_class
    list = [original_name.gsub(/[^\w]/, '-').downcase]
    list << 'mailbox--unseen' if unseen > 0
    list << 'mailbox--virtual' if unseen == -1
    list.join(' ')
  end

  def mails
    Webmail::Mail.where(mailbox: name)
  end

  private
    def validate_name
      self.name = self.name.tr('/', '.')
      self.name = "INBOX.#{name}" unless self.name =~ /^INBOX\./
      self.downcase_name = self.name.downcase
      self.depth = self.name.split('.').size - 1
    end

    def imap_create
      imap.conn.create original_name
    rescue Net::IMAP::NoResponseError => e
      rescue_imap_error(e)
    end

    def imap_update
      imap.conn.rename original_name(name_was), original_name
      Webmail::Mail.where(mailbox: name_was).update_all(mailbox: name)
    rescue Net::IMAP::NoResponseError => e
      rescue_imap_error(e)
    end

    def imap_delete
      imap.conn.delete original_name
      mails.destroy_all
    rescue Net::IMAP::NoResponseError => e
      rescue_imap_error(e)
    end

    def rescue_imap_error(e)
      errors.add :base, e.to_s
      return false
    end

  class << self
    def imap
      Webmail::Mail.imap
    end

    def inbox_unseen
      imap.conn.status('INBOX', ["UNSEEN"])["UNSEEN"]
    end

    def cache_key
      imap.cache_key
    end

    def imap_all
      items = imap.conn.list('INBOX', '*')
      items = cache_all(items)

      (imap.user.imap_special_mailboxes - items.map(&:name)).each do |name|
        item = self.new(cache_key)
        item.name = name
        item.sync.save
        items << item
      end

      items.map(&:stat)
      items.sort { |a, b| a.downcase_name <=> b.downcase_name }
    end

    def to_options
      options = []
      options << [I18n.t("webmail.box.inbox"), 'INBOX']
      options += where({}).map { |c| [c.short_name, c.original_name] }
      options
    end

    private
      def cache_all(list)
        names = list.map { |c| Net::IMAP.decode_utf7(c.name) }
        items = []

        Mongoid::Criteria.new(self).where(cache_key).each do |item|
          if names.index(item.name)
            items << item
            names.delete(item.name)
          else
            item.mails.destroy_all
            item.destroy
          end
        end

        names.each do |name|
          item = self.new(cache_key)
          item.name = name
          item.save
          items << item
        end

        items
      end
  end
end
