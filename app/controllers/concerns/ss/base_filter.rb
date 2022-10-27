module SS::BaseFilter
  extend ActiveSupport::Concern
  include SS::AuthFilter
  include SS::LayoutFilter
  include SS::ExceptionFilter
  include SS::CaptchaFilter
  include History::LogFilter

  included do
    cattr_accessor(:user_class) { SS::User }
    cattr_accessor :model_class

    helper SS::EditorHelper
    helper SS::JbuilderHelper
    before_action :set_model
    before_action :set_setting
    before_action :set_ss_assets
    before_action :logged_in?
    before_action :check_api_user
    before_action :set_logout_path_by_session
    rescue_from StandardError, with: :rescue_action
    layout "ss/base"
  end

  module ClassMethods
    private

    def model(cls)
      self.model_class = cls if cls
    end
  end

  def stylesheets
    @stylesheets || []
  end

  def stylesheet(path, **options)
    @stylesheets ||= []
    unless @stylesheets.any? { |css_path, css_options| css_path == path }
      if options.present?
        @stylesheets << [ path, options ]
      else
        @stylesheets << path
      end
    end
  end

  def javascripts
    @javascripts || []
  end

  def javascript(path, **options)
    @javascripts ||= []
    unless @javascripts.any? { |js_path, js_options| js_path == path }
      if options.present?
        @javascripts << [ path, options ]
      else
        @javascripts << path
      end
    end
  end

  private

  def set_model
    @model = self.class.model_class
  end

  def set_setting
    @cur_setting ||= Sys::Setting.first || Sys::Setting.new
  end

  def set_ss_assets
    if SS.config.ss.stylesheets.present?
      SS.config.ss.stylesheets.each { |m, options| options ? stylesheet(m, **options.symbolize_keys) : stylesheet(m) }
    end
    if SS.config.ss.javascripts.present?
      SS.config.ss.javascripts.each { |m, options| options ? javascript(m, **options.symbolize_keys) : javascript(m) }
    end
    stylesheet("colorbox")
    javascript("colorbox", defer: true)
  end

  def login_path_by_cookie
    path = cookies[:login_path].presence
    return path if path.present? && trusted_url?(path)

    sns_login_path
  end

  def logged_in?
    if @cur_user
      set_last_logged_in
      return @cur_user
    end

    return if login_by_access_token
    return if login_by_oauth2_token
    return if login_by_session

    unset_user

    if request.xhr?
      response.headers['ajaxRedirect'] = true
      return render plain: ''
    end

    respond_to do |format|
      format.html do
        login_path = login_path_by_cookie
        ref = request.env["REQUEST_URI"].to_s
        ref = '' if ref.present? && !trusted_url?(ref)
        if ref.blank? || ref == login_path || params[:action] == "login"
          redirect_to login_path
        else
          redirect_to "#{login_path}?#{{ ref: ref }.to_query}"
        end
      end
      format.any { render json: :error, status: :unauthorized }
    end
  end

  def login_by_access_token
    @cur_user, login_path, logout_path = get_user_by_access_token
    SS.current_user = @cur_user
    SS.current_token = nil
    SS.change_locale_and_timezone(SS.current_user)
    return false if !@cur_user

    set_user(@cur_user, session: true, login_path: login_path, logout_path: logout_path)

    # persistent session to database by redirecting to self path
    redirect = SS::AccessToken.remove_access_token_from_query(request.fullpath)
    redirect = ::Addressable::URI.parse(redirect)
    # redirect_to [ redirect.path, redirect.query.presence ].compact.join("?")
    redirect_to redirect.request_uri
    true
  end

  def login_by_oauth2_token
    @cur_user, token = get_user_by_oauth2_token
    SS.current_user = @cur_user
    SS.current_token = token
    SS.change_locale_and_timezone(SS.current_user)
    return false if !@cur_user

    # no need to keep sessions with token auth
    request.session_options[:skip] = true
    return true
  end

  def login_by_session
    @cur_user = SS.current_user = get_user_by_session
    SS.current_token = nil
    SS.change_locale_and_timezone(SS.current_user)
    return false if !@cur_user

    set_last_logged_in
    return true
  end

  def set_user(user, opts = {})
    if opts[:session]
      old_session_id = session.id
      reset_session if SS.config.sns.logged_in_reset_session
      form_authenticity_token
      session[:user] = {
        "user_id" => user.id,
        "remote_addr" => remote_addr,
        "user_agent" => request.user_agent,
        "last_logged_in" => Time.zone.now.to_i
      }
      session[:user]["password"] = SS::Crypto.encrypt(opts[:password]) if opts[:password].present?
      Rails.logger.info("renew session: old id=#{old_session_id}, new id=#{session.id}")
    end
    set_login_path_to_cookie(opts[:login_path] || request_path)
    session[:logout_path] = opts[:logout_path]
    redirect_to sns_mypage_path if opts[:redirect]
    @cur_user = SS.current_user = user
    SS.change_locale_and_timezone(SS.current_user)
  end

  def unset_user(opt = {})
    session[:user] = nil
    redirect_to login_path_by_cookie if opt[:redirect]
    @cur_user = SS.current_user = nil
    SS.current_token = nil
    SS.change_locale_and_timezone(SS.current_user)
  end

  def check_api_user
    return if @cur_user.blank?
    return unless @cur_user.restricted_api_only?
    return if request.path_info.end_with?('.json')

    # api user only allowd .json
    raise "403"
  end

  def set_logout_path_by_session
    @logout_path = session[:logout_path].presence
  end

  def set_login_path_to_cookie(path)
    if path.blank?
      cookies.delete(:login_path)
      return
    end

    value = { value: path, http_only: true }
    value[:same_site] = SS.config.ss.session["same_site"] if !SS.config.ss.session["same_site"].nil?
    value[:secure] = SS.config.ss.session["secure"] if !SS.config.ss.session["secure"].nil?

    cookies[:login_path] = value
  end

  def rescue_action(exception)
    render_exception!(exception)
  end
end
