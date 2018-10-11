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
    raise "404" unless %i[account group].include?(@webmail_mode)
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
    if @webmail_mode == :group
      raise "403" if !@cur_user.webmail_permitted_all?(:use_webmail_group_imap_setting)
      group = @cur_user.groups.find_by(id: params[:account])
      @imap = group.initialize_imap
    elsif params.key?(:account)
      @imap = @cur_user.initialize_imap(params[:account].to_i)
    end
    return if @imap.blank?

    @imap_setting = @imap.setting

    if @webmail_mode == :account && params[:account].to_i == 0
      if @cur_user.webmail_permitted_any?(:edit_webmail_user_accounts)
        # 既定の個人アカウントの場合にのみ webmail_account_setting_path とする。
        @redirect_path = webmail_account_setting_path
      else
        # 個人アカウントを管理する権限がないので、エラーを表示する。
        @redirect_path = webmail_login_failed_path(
          account: params[:account] || @cur_user.imap_default_index, webmail_mode: @webmail_mode)
      end
    else
      # それ以外（追加の個人アカウントやグループ代表メールアカウント）の場合、エラーを表示する。
      @redirect_path = webmail_login_failed_path(
        account: params[:account] || @cur_user.imap_default_index, webmail_mode: @webmail_mode)
    end
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
