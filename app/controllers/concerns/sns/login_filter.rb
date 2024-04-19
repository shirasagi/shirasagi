module Sns::LoginFilter
  extend ActiveSupport::Concern

  included do
    protect_from_forgery except: :remote_login
    before_action :set_organization
    after_action :user_logged_out, only: [:logout]
    skip_before_action :verify_authenticity_token, raise: false unless SS.config.env.protect_csrf
    prepend_view_path "app/views/sns/login"
    layout "ss/login"
    navi_view nil
    helper_method :default_logged_in_path
  end

  private

  def remote_login?
    SS.config.sns.remote_login
  end

  def default_logged_in_path
    SS.config.sns.logged_in_page
  end

  def render_login(user, email_or_uid, **opts)
    alert = opts.delete(:alert).presence || t("sns.errors.invalid_login")

    if user
      opts[:session] ||= true
      set_user user, **opts

      respond_to do |format|
        format.html { redirect(true) }
        format.json { head :no_content }
      end
    else
      @item = user_class.new
      @item.email = email_or_uid if email_or_uid.present?
      respond_to do |format|
        flash[:alert] = alert
        format.html { render template: "login" }
        format.json { render json: alert, status: :unprocessable_entity }
      end
    end
  end

  def set_organization
    return if @cur_organization.present?

    organizations = SS::Group.organizations.where(domains: request_host)
    return if organizations.size != 1

    @cur_organization = SS.current_organization = organizations.first
  end

  def user_logged_out
    @cur_user.logged_out if @cur_user
  end

  def normalize_url(url)
    return unless url.respond_to?(:scheme)
    return unless %w(http https).include?(url.scheme)

    # url.fragment = nil
    # url.query = nil
    url
  end

  def back_to_url
    back_to = params[:back_to].to_s
    return default_logged_in_path if back_to.blank?

    @request_url ||= ::Addressable::URI.parse(request.url)
    back_to_url = ::Addressable::URI.join(@request_url, back_to) rescue nil
    return default_logged_in_path if back_to_url.blank?

    back_to_url = normalize_url(back_to_url)
    return default_logged_in_path if back_to_url.blank? || !myself_url?(back_to_url)

    back_to_url.to_s
  end

  def login_path
    sns_login_path
  end

  def logout_path
    sns_logout_path
  end

  def mfa_login_path
    sns_mfa_login_path
  end

  public

  def login
    if !request.post?
      # retrieve parameters from get parameter. this is bookmark support.
      @item = self.user_class.new email: params[:email]
      return render(template: :login)
    end

    safe_params     = get_params
    email_or_uid    = safe_params[:email].presence || safe_params[:uid]
    password        = safe_params[:password]
    encryption_type = safe_params[:encryption_type]

    if encryption_type.present?
      password = SS::Crypto.decrypt(password, type: encryption_type) rescue nil
    end

    @item = begin
      if @cur_organization
        self.user_class.organization_authenticate(@cur_organization, email_or_uid, password) rescue nil
      elsif @cur_site
        self.user_class.site_authenticate(@cur_site, email_or_uid, password) rescue nil
      else
        self.user_class.authenticate(email_or_uid, password) rescue nil
      end
    end
    if @item.blank? || @item.disabled? || @item.locked?
      render_login(
        nil, email_or_uid, session: true, password: password, login_path: login_path, logout_path: logout_path)
      return
    end
    if Sys::Auth::Setting.instance.mfa_otp_use?(request)
      session[:authenticated_in_1st_step] = {
        user_id: @item.id,
        password: password,
        ref: params[:ref].to_s,
        login_path: login_path,
        logout_path: logout_path,
        authenticated_at: Time.zone.now.to_i
      }
      redirect_to mfa_login_path
      return
    end

    @item = @item.try_switch_user || @item

    render_login(
      @item, email_or_uid, session: true, password: password, login_path: login_path, logout_path: logout_path)
  end

  def logout
    put_history_log
    # discard all session info
    reset_session if SS.config.sns.logged_in_reset_session
    respond_to do |format|
      format.html { redirect_to login_path_by_cookie }
      format.json { head :no_content }
    end
  end

  def redirect(login = false)
    ref = params[:ref].to_s
    if ref.blank?
      redirect_to back_to_url
      return
    end

    @request_url = ::Addressable::URI.parse(request.url)
    @url = ::Addressable::URI.join(@request_url, ref) rescue nil
    if @url.blank?
      redirect_to back_to_url
      return
    end

    @url = normalize_url(@url)
    if @url.blank?
      redirect_to back_to_url
      return
    end

    if trusted_url?(@url)
      redirect_to @url.to_s
      return
    end

    if login
      redirect_to back_to_url
      return
    end

    render template: "redirect"
  end
end
