require "net/imap"
module Webmail::ImapFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_imap
    after_action :unset_imap
    rescue_from Net::IMAP::NoResponseError, with: :rescue_no_response_error
  end

  private
    def set_imap
      @imap = Webmail::Imap.new
      return if @imap.login(@cur_user)

      redirect_to webmail_account_setting_path
    end

    def unset_imap
      @imap.disconnect rescue nil
      @imap = nil
    end

    def rescue_no_response_error(e)
      render plain: e.to_s, layout: true
    end
end
