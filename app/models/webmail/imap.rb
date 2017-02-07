require "net/imap"
class Webmail::Imap
  include ActiveModel::Validations
  #include Singleton

  cattr_accessor :instance

  # Net::IMAP
  attr_accessor :conn

  # IMAP settings
  attr_accessor :conf

  # Login user
  attr_accessor :user

  # Connect IMAP server
  def login(user)
    self.user = user
    self.conf = user.imap_settings

    begin
      self.conn = Net::IMAP.new conf[:host], conf[:options]
      conn.authenticate conf[:auth_type], conf[:account], conf[:password]
      self.class.instance = self
    rescue SocketError, Net::IMAP::NoResponseError => e
      errors.add :base, e.to_s
      return @logged_in = false
    end

    @logged_in = true
  end

  def logged_in?
    @logged_in == true
  end

  def mailbox
    @mailbox
  end

  def examine(mailbox = @mailbox)
    @mailbox = mailbox
    conn.examine(mailbox)
  end

  def select(mailbox = @mailbox)
    @mailbox = mailbox
    conn.select(mailbox)
  end

  def cache_key
    { host: conf[:host], account: conf[:account] }
  end

  def quota_info
    @quota_info ||= conn.getquotaroot('INBOX')[1]
  end

  def quota_total
    quota_info.quota.to_i * 1024
  end

  def quota_used
    quota_info.usage.to_i * 1024
  end

  def quota_per
    (quota_used.to_f / quota_total.to_f * 100).to_f
  end
end
