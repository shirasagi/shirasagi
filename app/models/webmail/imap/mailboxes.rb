module Webmail::Imap
  class Mailboxes
    include Webmail::ImapAccessor

    def initialize(imap)
      @imap = imap
      @list = cache_find
      sort
    end

    def sort
      @list.sort_by! do |item|
        if imap.inbox?(item.name)
          "#{01}#{item.name.downcase}"
        elsif !imap.special_mailbox?(item.name)
          "#{02}#{item.name.downcase}"
        else
          "#{03}#{item.name.downcase}"
        end
      end
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

    def update_status
      @list.each { |item| item.status.save }
      self
    end

    def apply_recent_filters
      return 0 if inbox.status.recent == 0

      imap.examine('INBOX')
      filters = Webmail::Filter.user(imap.user).imap_setting(imap.user, imap.setting).enabled.entries

      filters.each do |filter|
        filter.imap = imap
        filter.uids = filter.uids_search(['NEW'])
      end

      counts = filters.map do |filter|
        filter.uids_apply(filter.uids)
      end

      update_status
      counts.inject(:+) || 0
    end

    def cache_find
      Webmail::Mailbox.where(imap.account_scope).entries.each { |item| item.imap = imap }
    end

    def imap_find
      imap.conn.list('', '*')
    end

    def create_mailboxes(list)
      list.map do |ml|
        item = Webmail::Mailbox.new(imap.account_scope)
        item.imap = imap
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
        item.imap = imap
        item.name = name
        item.sync.save || item.sync(false).save
        #status
        item
      end
    end
  end
end
