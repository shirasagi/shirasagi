require "net/imap"
module Webmail::Imap
  class Base
    include Webmail::Imap::UidsCommand

    attr_accessor :user, :conf, :setting, :conn, :error, :address
    attr_reader :sent_box, :draft_box, :trash_box

    def initialize(user, setting)
      self.user  = user
      self.conf  = setting.imap_settings(user.imap_default_settings)
      self.setting = setting

      @address   = conf[:address]
      @sent_box  = conf[:imap_sent_box]
      @draft_box = conf[:imap_draft_box]
      @trash_box = conf[:imap_trash_box]

      self
    end

    def email_address
      return %(#{conf[:from]} <#{address}>) if conf[:from].present?
      %(#{user.name} <#{address}>)
    end

    def login
      begin
        self.conn = Net::IMAP.new conf[:host], conf[:options]
        conn.authenticate conf[:auth_type], conf[:account], conf[:password]
        return true
      rescue SocketError, Net::IMAP::NoResponseError, Errno::ECONNREFUSED => e
        self.error = e.to_s
      end
      false
    end

    def disconnect
      if conn
        conn.disconnect rescue nil
      end
      self.conn = nil
      self.conf = nil
      self.user = nil
      self.error = nil
    end

    def mailbox
      @mailbox
    end

    def account_scope
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
