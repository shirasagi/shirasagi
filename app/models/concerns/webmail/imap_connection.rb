module Webmail::ImapConnection
  extend ActiveSupport::Concern

  def imap
    Webmail::Imap.imap
  end

  class_methods do
    def imap
      Webmail::Imap.imap
    end
  end
end
