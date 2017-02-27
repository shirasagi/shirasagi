module Webmail::Imap
  class Mailboxes
    include Webmail::ImapAccessor

    def initialize
      @list = cache_find
      sort
    end

    def sort
      @list.sort_by! { |item| item.locale_name.downcase }
      self
    end

    def all
      @list
    end

    def inbox
      @list.find { |m| m.original_name == 'INBOX' }
    end

    def without_inbox
      @list.reject { |m| m.original_name == 'INBOX' }
    end

    def load
      reload? ? reload.sort : self
    end

    def reload?
      return true if @list.blank?
      create_special_mailboxes.present?
    end

    def reload
      cache_names = @list.map(&:original_name)

      imap_items = imap_find
      imap_names = imap_items.map(&:name)

      create_names = imap_names - cache_names
      create_items = imap_items.select { |ml| create_names.include?(ml.name) }
      create_mailboxes(create_items)

      delete_names = cache_names - imap_names
      @list.select { |item| item.delete if delete_names.include?(item.original_name) }

      create_special_mailboxes

      @list = cache_find
      @list.each do |item|
        next if create_names.include?(item.original_name)
        if ml = imap_items.find { |ml| ml.name == item.original_name }
          item.attr = ml.attr.map(&:to_s)
        end
        item.status.save
      end
      self
    end

    def reload_info
      cache_names = @list.map(&:original_name)
      imap_names = imap_find.map(&:name)
      info = {
        create: (imap_names - cache_names).map { |n| Net::IMAP.decode_utf7(n) },
        delete: (cache_names - imap_names).map { |n| Net::IMAP.decode_utf7(n) }
      }
      info[:create] += (imap.special_mailboxes - @list.map(&:name))
      info
    end

    def cache_find
      Webmail::Mailbox.where(imap.account_scope).entries
    end

    def imap_find
      imap.conn.list('', '*')
    end

    def create_mailboxes(list)
      list.map do |ml|
        item = Webmail::Mailbox.new(imap.account_scope)
        item.parse_mailbox_list(ml)
        item.status
        item.save
        item
      end
    end

    def create_special_mailboxes
      names = imap.special_mailboxes - @list.map(&:name)
      names.each do |name|
        item = Webmail::Mailbox.new(imap.account_scope)
        item.name = name
        item.sync.save || item.sync(false).save
        #status
        item
      end
    end
  end
end
