module Webmail::ImapPermission
  extend ActiveSupport::Concern

  def allowed?(action, imap, opts = {})
    return true if new_record?

    scope = imap.account_scope
    host == scope[:host] && account == scope[:account]
  end

  module ClassMethods
    def allowed?(action, user, opts = {})
      self.new.allowed?(action, user, opts)
    end

    def allow(action, imap, opts = {})
      where(imap.account_scope)
    end
  end
end
