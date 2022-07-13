module Sns::LoginFilter
  extend ActiveSupport::Concern

  included do
    protect_from_forgery except: :remote_login
    before_action :set_organization
    after_action :user_logged_in, only: [:login]
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

  def render_login(user, email_or_uid, opts = {})
    alert = opts.delete(:alert).presence || t("sns.errors.invalid_login")

    if user
      return if render_one_time_password(user)

      opts[:session] ||= true
      set_user user, opts

      respond_to do |format|
        format.html { redirect(true) }
        format.json { head :no_content }
      end
    else
      @item = user_class.new
      @item.email = email_or_uid if email_or_uid.present?
      @alert = alert
      respond_to do |format|
        format.html { render template: "login" }
        format.json { render json: alert, status: :unprocessable_entity }
      end
    end
  end

  def render_one_time_password(user)
    return unless user.otpw_enabled? # organization exists
    return if user.organization.gws_group.otpw_allowlist_request?(remote_addr)

    @otpw_view = :password
    safe_params = get_params

    if safe_params[:in_otpw_password].present?
      @otpw_view = :password
      valid = user.otpw_authenticate_password(safe_params[:in_otpw_password])
      return if valid

      @alert = user.errors.full_messages.first
      user.errors.clear
      return render template: "login"
    end

    if safe_params[:in_otpw_email].present?
      password = user.otpw_set_new_password
      email = user.otpw_find_email(safe_params[:in_otpw_email])

      SS::Mailer.one_time_password_mail(user, email).deliver_now if email
      return render template: "login"
    end

    @otpw_view = :email
    render template: "login"
  end

  def set_organization
    return if @cur_organization.present?

    organizations = SS::Group.organizations.where(domains: request_host)
    return if organizations.size != 1

    @cur_organization = SS.current_organization = organizations.first
  end

  def user_logged_in
    @cur_user.logged_in if @cur_user
  end

  def user_logged_out
    @cur_user.logged_out if @cur_user
  end

  def normalize_url(url)
    return unless url.respond_to?(:scheme)
    return unless %w(http https).include?(url.scheme)

    url.fragment = nil
    url.query = nil
    url
  end

  def back_to_url
    back_to = params[:back_to].to_s
    return default_logged_in_path if back_to.blank?

    @request_url ||= URI.parse(request.url)
    back_to_url = URI.join(@request_url, back_to) rescue nil
    return default_logged_in_path if back_to_url.blank?

    back_to_url = normalize_url(back_to_url)
    return default_logged_in_path if back_to_url.blank? || !myself_url?(back_to_url)

    back_to_url.to_s
  end

  public

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

    @request_url = URI.parse(request.url)
    @url = URI.join(@request_url, ref) rescue nil
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
