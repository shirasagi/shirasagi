require "net/imap"
class Webmail::Mailbox
  include SS::Document
  include SS::Reference::User
  include SS::FreePermission

  # Webmail::Imap
  cattr_accessor :imap

  attr_accessor :sync

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

  def basename
    name.sub(/.*\./, '')
  end

  def original_name(name = self.name)
    Net::IMAP.encode_utf7(name)
  end

  def css_class
    original_name.tr('.', '-').downcase
  end

  def mails
    Webmail::Mail.where(mailbox: name)
  end

  def unseen_size
    return @unseen_size if @unseen_size
    imap.conn.examine(original_name)
    @unseen_size = imap.conn.uid_search(%w(UNSEEN), 'UTF-8').size
  rescue Net::IMAP::NoResponseError
    @unseen_size = 0
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
    def cache_key
      imap.cache_key
    end

    def imap_all
      items = imap.conn.list('INBOX', '*')
      items = cache_all(items)

      (imap.user.imap_special_mailboxes - items.map(&:name)).each do |name|
        item = self.new(cache_key)
        item.sync = true
        item.name = name
        item.save
        items << item
      end

      items.sort { |a, b| a.downcase_name <=> b.downcase_name }
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
