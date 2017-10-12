require "net/imap"
module Webmail::BaseFilter
  extend ActiveSupport::Concern
  include Sns::BaseFilter

  included do
    helper Webmail::MailHelper
    navi_view "webmail/main/navi"
    before_action :set_webmail_mode
    before_action :imap_disconnect
    before_action :imap_initialize
    # before_action :imap_login
    after_action :imap_disconnect
    rescue_from Net::IMAP::NoResponseError, with: :rescue_impa_no_response_error
  end

  private

  def set_webmail_mode
    @ss_mode = :webmail
  end

  def set_crumbs
    # @crumbs << [t("modules.webmail"), webmail_mails_path]
  end

  def imap_initialize
    @imap_setting = @cur_user.imap_settings[params[:account].to_i]
    @imap_setting ||= Webmail::ImapSetting.new
    @imap = Webmail::Imap::Base.new(@cur_user, @imap_setting)
  end

  def imap_disconnect
    @imap.disconnect if @imap
  end

  def imap_login
    return if @imap.login
    redirect_to webmail_account_setting_path
  end

  def rescue_imap_no_response_error(e)
    raise e if Rails.env.development?
    render plain: e.to_s, layout: true
  end
end
