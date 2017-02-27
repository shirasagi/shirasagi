require "net/imap"
module Webmail::ImapFilter
  extend ActiveSupport::Concern

  included do
    before_action :imap_init
    before_action :imap_login
    after_action :imap_disconnect
    rescue_from Net::IMAP::NoResponseError, with: :rescue_no_response_error
  end

  private
    def imap_init
      @imap = Webmail::Imap.set_user(@cur_user)
    end

    def imap_login
      return if @imap.login
      redirect_to webmail_account_setting_path
    end

    def imap_disconnect
      @imap.disconnect
    end

    def rescue_no_response_error(e)
      raise e if Rails.env.development?
      render plain: e.to_s, layout: true
    end
end
