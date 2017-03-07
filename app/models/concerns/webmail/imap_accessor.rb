module Webmail::ImapAccessor
  extend ActiveSupport::Concern

  def imap
    Webmail::Imap
  end

  class_methods do
    def imap
      Webmail::Imap
    end
  end
end
