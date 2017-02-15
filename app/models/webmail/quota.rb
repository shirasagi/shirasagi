require "net/imap"
class Webmail::Quota
  def initialize(conn)
    begin
      @info   = conn.getquotaroot('INBOX')[1]
      @exists = true
    rescue Net::IMAP::ResponseParseError
    end
  end

  def exist?
    @exists.present?
  end

  def total
    @info.quota.to_i * 1024
  end

  def used
    @info.usage.to_i * 1024
  end

  def per
    (used.to_f / total.to_f * 100).to_f
  end
end
