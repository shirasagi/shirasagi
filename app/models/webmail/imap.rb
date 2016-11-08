require "net/imap"
class Webmail::Imap
  include ActiveModel::Validations

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

    if conf.blank?
      errors.add :base, "no settings"
      return false
    end

    begin
      self.conn = Net::IMAP.new(conf[:host])
      conn.authenticate('LOGIN', conf[:account], conf[:password])
    rescue Net::IMAP::NoResponseError => e
      errors.add :base, e.to_s
      return @logged_in = false
    end

    Webmail::Mail.imap = self
    Webmail::Mailbox.imap = self
    @logged_in = true
  end

  def logged_in?
    @logged_in == true
  end
end
