module SS::BaseFilter
  extend ActiveSupport::Concern
  include SS::AuthFilter
  include SS::LayoutFilter
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

  def stylesheet(path)
    @stylesheets ||= []
    @stylesheets << path unless @stylesheets.include?(path)
  end

  def javascripts
    @javascripts || []
  end

  def javascript(path)
    @javascripts ||= []
    @javascripts << path unless @javascripts.include?(path)
  end

  private

  def set_model
    @model = self.class.model_class
  end

  def set_setting
    @cur_setting ||= Sys::Setting.first || Sys::Setting.new
  end

  def set_ss_assets
    SS.config.ss.stylesheets.each { |m| stylesheet(m) } if SS.config.ss.stylesheets.present?
    SS.config.ss.javascripts.each { |m| javascript(m) } if SS.config.ss.javascripts.present?
    stylesheet("/assets/css/colorbox/colorbox.css")
  end

  def login_path_by_cookie
    cookies[:login_path].presence || sns_login_path
  end

  def logged_in?
    if @cur_user
      set_last_logged_in
      return @cur_user
    end

    @cur_user = get_user_by_access_token
    if @cur_user
      redirct = request.fullpath.sub(/(\?|&)access_token=.*/, '')
      set_user(@cur_user, session: true, login_path: @login_path, logout_path: @logout_path)
      return redirect_to(redirct)
    end

    @cur_user = get_user_by_session
    if @cur_user
      set_last_logged_in
      return @cur_user
    end

    unset_user

    if request.xhr?
      response.headers['ajaxRedirect'] = true
      return render plain: ''
    end

    respond_to do |format|
      format.html do
        login_path = login_path_by_cookie
        ref = request.env["REQUEST_URI"]
        if ref == login_path || params[:action] == "login"
          redirect_to login_path
        else
          redirect_to "#{login_path}?ref=" + CGI.escape(ref.to_s)
        end
      end
      format.json { render json: :error, status: :unauthorized }
    end
  end

  def set_user(user, opts = {})
    if opts[:session]
      reset_session
      session[:user] = {
        "user_id" => user.id,
        "remote_addr" => remote_addr,
        "user_agent" => request.user_agent,
        "last_logged_in" => Time.zone.now.to_i
      }
      session[:user]["password"] = SS::Crypt.encrypt(opts[:password]) if opts[:password].present?
    end
    set_login_path_to_cookie(opts[:login_path] || request_path)
    session[:logout_path] = opts[:logout_path]
    redirect_to sns_mypage_path if opts[:redirect]
    @cur_user = user
  end

  def unset_user(opt = {})
    session[:user] = nil
    redirect_to login_path_by_cookie if opt[:redirect]
    @cur_user = nil
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

  def render_exception!(exception)
    if exception.is_a?(Job::SizeLimitPerUserExceededError)
      render_job_size_limit(exception)
      return
    end

    backtrace_cleaner = request.get_header("action_dispatch.backtrace_cleaner")
    wrapper = ::ActionDispatch::ExceptionWrapper.new(backtrace_cleaner, exception)
    if exception.is_a?(RuntimeError) && exception.message.numeric?
      status_code = Integer(exception.message)
    else
      status_code = wrapper.status_code
    end

    @ss_rescue = { status: status_code }
    @wrapper = wrapper if Rails.env.development?

    if @ss_mode == :cms && !@cur_site
      @ss_mode = nil
    elsif @ss_mode == :gws && !@cur_site
      @ss_mode = nil
    end

    render(
      file: "ss/rescues/index", layout: @cur_user ? "ss/base" : "ss/login", status: status_code,
      type: request.xhr? ? "text/plain" : "text/html", formats: request.xhr? ? :text : :html
    )
  rescue => e
    Rails.logger.info("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    raise exception
  end

  def render_job_size_limit(error)
    referer_uri = URI.parse(request.referer)
    begin
      if @item.present?
        @item.errors.add(:base, error.to_s)
        flash[:notice] = error.to_s
        render(Rails.application.routes.recognize_path(referer_uri.path))
      else
        redirect_to(referer_uri.path, notice: error.to_s)
      end
    rescue ActionView::MissingTemplate
      redirect_to(referer_uri.path, notice: error.to_s)
    end
  end
end
