require "net/imap"
class Webmail::Mailbox
  include SS::Document
  include SS::Reference::User

  # Webmail::Imap
  cattr_accessor :imap

  field :host, type: String
  field :original_names, type: Array
  field :name, type: String
  field :order, type: Integer, default: 0
  field :depth, type: Integer

  default_scope -> { order_by order: 1, name: 1 }

  def set_mailbox_list(ml)
    names = ml.name.split(ml.delim)

    self.attributes = {
      original_names: names,
      name: names.map { |n| Net::IMAP.decode_utf7(n) }.join('.'),
      depth: names.size - 1
    }
  end

  def basename
    Net::IMAP.decode_utf7(original_names.last)
  end

  def original_name
    original_names.join('.')
  end

  def css_class
    original_name.tr('.', '-').downcase
  end

  class << self
    def imap_all
      items = Mongoid::Criteria.new(self).where(cache_key)
      return items if items.present?

      items = imap.conn.list('INBOX', '*')
      items.sort! { |a, b| a.name <=> b.name }
      items.map do |ml|
        item = self.new(cache_key)
        item.set_mailbox_list(ml)
        item.save
        item
      end
    end

    private
      def cache_key
        { user_id: imap.user.id, host: imap.conf[:host] }
      end
  end
end
