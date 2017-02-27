require "net/imap"
module Webmail::Imap
  include Webmail::Imap::UidsCommand

  cattr_accessor :user, :conf, :conn, :error

  class << self
    def set_user(user)
      disconnect
      self.user  = user
      self.conf  = user.imap_settings
      self
    end

    def login
      begin
        self.conn = Net::IMAP.new conf[:host], conf[:options]
        conn.authenticate conf[:auth_type], conf[:account], conf[:password]
        return true
      rescue SocketError, Net::IMAP::NoResponseError => e
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

    def sent_box
      user.imap_sent_box
    end

    def draft_box
      user.imap_draft_box
    end

    def trash_box
      user.imap_trash_box
    end

    def sent_box?(name)
      (name =~ /^#{Regexp.escape(sent_box)}(\.|$)/).present?
    end

    def mails
      Webmail::Imap::Mail.new
    end

    def mailboxes
      Webmail::Imap::Mailboxes.new
    end

    def quota
      Webmail::Imap::Quota.new
    end
  end
end
