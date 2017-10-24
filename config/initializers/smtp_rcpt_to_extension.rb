# monkey patch for RCPT TO Extension
# ref : https://github.com/ruby/ruby/blob/trunk/lib/net/smtp.rb

module Net
  module SmtpRcptToExtension
    def rcptto(to_addr)
      if to_addr.to_s =~ /^<[^>]+>/
        getok("RCPT TO:#{to_addr}")
      else
        super
      end
    end
  end

  class SMTP
    prepend SmtpRcptToExtension
  end
end
