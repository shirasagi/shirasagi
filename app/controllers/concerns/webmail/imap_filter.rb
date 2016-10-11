module Webmail::ImapFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_imap
  end

  private
    def set_imap
      @imap = Webmail::Imap.new
      return if @imap.login(@cur_user)

      redirect_to webmail_account_setting_path
    end
end
