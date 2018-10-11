require "net/imap"
module Webmail::Imap
  class Base
    include Webmail::Imap::UidsCommand

    attr_accessor :conf, :setting, :conn, :error, :address, :email_address
    attr_accessor :sent_box, :draft_box, :trash_box

    private_class_method :new

    class << self
      def new_by_user(user, setting)
        ret = new
        ret.conf = conf = setting.imap_settings(user.imap_default_settings)
        ret.setting = setting

        ret.address = address = conf[:address]
        ret.email_address = format_email_addree(conf[:from].presence || user.name, address)
        ret.sent_box = conf[:imap_sent_box]
        ret.draft_box = conf[:imap_draft_box]
        ret.trash_box = conf[:imap_trash_box]

        ret
      end

      def new_by_group(group, setting)
        ret = new
        ret.conf = conf = setting.imap_settings(group.imap_default_setting)
        ret.setting = setting

        ret.address = address = conf[:address].presence || group.contact_email
        ret.email_address = format_email_addree(conf[:from].presence || group.name, address)
        ret.sent_box = conf[:imap_sent_box]
        ret.draft_box = conf[:imap_draft_box]
        ret.trash_box = conf[:imap_trash_box]

        ret
      end

      def format_email_addree(name, address)
        if name.present?
          %(#{name} <#{address}>)
        else
          address
        end
      end
    end

    def login
      begin
        host = conf[:host]
        options = conf[:options].symbolize_keys
        self.conn = Net::IMAP.new host, options
        conn.authenticate conf[:auth_type], conf[:account], conf[:password]
        return true
      rescue SocketError, Net::IMAP::Error, Errno::ECONNREFUSED => e
        self.error = e.to_s
      end
      false
    end

    def disconnect
      if conn
        conn.disconnect rescue nil
      end
      self.conn = nil
      self.error = nil
    end

    def mailbox
      @mailbox
    end

    def account_scope
      # host and account are required
      return if conf[:host].blank? || conf[:account].blank?

      { host: conf[:host], account: conf[:account] }
    end

    def examine(mailbox = @mailbox)
      @mailbox = mailbox
      conn.examine(mailbox)
    end

    def select(mailbox = @mailbox)
      @mailbox = mailbox
      conn.select(mailbox)
    end

    def special_mailboxes
      [sent_box, draft_box, trash_box]
    end

    def special_mailbox?(name)
      draft_box?(name) || sent_box?(name) || trash_box?(name)
    end

    def draft_box?(name)
      "#{name}.".start_with?("#{draft_box}.")
    end

    def sent_box?(name)
      "#{name}.".start_with?("#{sent_box}.")
    end

    def trash_box?(name)
      "#{name}.".start_with?("#{trash_box}.")
    end

    def inbox?(name)
      (name =~ /^INBOX(\.|$)/).present?
    end

    def mails
      Webmail::Imap::Mail.new(self)
    end

    def mailboxes
      Webmail::Imap::Mailboxes.new(self)
    end

    def quota
      Webmail::Imap::Quota.new(self)
    end
  end
end
