require "net/imap"
module Webmail::BaseFilter
  extend ActiveSupport::Concern
  include Sns::BaseFilter

  included do
    self.user_class = Webmail::User
    helper Webmail::MailHelper
    navi_view "webmail/main/navi"
    before_action :set_webmail_mode
    before_action :validate_service, if: ->{ SS.config.service.webmail_limitation.present? }
    before_action :set_webmail_logged_in, if: ->{ @cur_user }
    before_action :imap_disconnect
    before_action :imap_initialize, if: ->{ @cur_user }
    # before_action :imap_login
    after_action :imap_disconnect
    rescue_from Net::IMAP::NoResponseError, with: :rescue_imap_no_response_error
  end

  private

  def set_webmail_mode
    @ss_mode = :webmail
    @webmail_mode = params[:webmail_mode].try(:to_sym) || :account
  end

  def validate_service
    return unless @cur_org = @cur_user.organization
    return unless @account = Service::Account.where(organization_ids: @cur_org.id).first
    return if @account.webmail_enabled?
    msg = [I18n.t("service.messages.disabled_app", name: I18n.t("modules.webmail"))]
    msg << I18n.t("service.messages.over_quota") if @account.webmail_quota_over?
    render html: msg.join("<br />").html_safe
  end

  def set_webmail_logged_in
    webmail_session = session[:webmail]
    webmail_session ||= {}
    webmail_session['last_logged_in'] ||= begin
      Webmail::History.info!(
        :controller, @cur_user,
        path: request.path, controller: self.class.name.underscore, action: action_name,
        model: Webmail::User.name.underscore, item_id: @cur_user.id, mode: 'login', name: @cur_user.name
      )
      Time.zone.now.to_i
    end

    session[:webmail] = webmail_session
  end

  def set_crumbs
    # @crumbs << [t("modules.webmail"), webmail_mails_path]
  end

  def imap_initialize
    @imap_setting = if @webmail_mode == :group
                      @cur_user.groups.find_by(id: params[:account]).imap_setting
                    elsif params.key?(:account)
                      @cur_user.imap_settings[params[:account].to_i]
                    end

    if @imap_setting
      @redirect_path = webmail_login_failed_path(account: params[:account], webmail_mode: @webmail_mode)
    else
      @redirect_path  = if @webmail_mode == :group
                          sys_group_path(id: params[:account])
                        else
                          webmail_account_setting_path
                        end

      @imap_setting = Webmail::ImapSetting.new
    end

    @imap = Webmail::Imap::Base.new(@cur_user, @imap_setting)

    return if @webmail_mode != :group
    address = @imap_setting.address.presence || Sys::Group.where(id: params[:account]).first.try(:contact_email)
    return if address.blank?
    @imap.address = address
  end

  def imap_disconnect
    @imap.disconnect if @imap
  end

  def imap_login
    return if @imap.login
    redirect_to @redirect_path
  end

  def rescue_imap_no_response_error(exception)
    raise exception if Rails.env.development?
    render plain: exception.to_s, layout: true
  end
end
