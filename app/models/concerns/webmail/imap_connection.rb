module Webmail::ImapConnection
  extend ActiveSupport::Concern

  def imap
    Webmail::Imap.instance
  end

  class_methods do
    def imap
      Webmail::Imap.instance
    end
  end
end
