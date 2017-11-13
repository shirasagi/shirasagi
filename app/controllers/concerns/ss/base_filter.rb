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
    before_action :set_ss_assets
    before_action :logged_in?
    before_action :check_api_user
    before_action :set_logout_path_by_session
    after_action :put_history_log, if: ->{ !request.get? && response.code =~ /^3/ }
    rescue_from RuntimeError, with: :rescue_action
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

  def set_ss_assets
    SS.config.ss.stylesheets.each { |m| stylesheet(m) } if SS.config.ss.stylesheets.present?
    SS.config.ss.javascripts.each { |m| javascript(m) } if SS.config.ss.javascripts.present?
    stylesheet("/assets/css/colorbox/colorbox.css")
  end

  def login_path_by_cookie
    cookies[:login_path] || sns_login_path
  end

  def logged_in?
    if @cur_user
      set_last_logged_in
      return @cur_user
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
      session[:user] = {
        "user_id" => user.id,
        "remote_addr" => remote_addr,
        "user_agent" => request.user_agent,
        "last_logged_in" => Time.zone.now.to_i }
      session[:user]["password"] = SS::Crypt.encrypt(opts[:password]) if opts[:password].present?
    end
    cookies[:login_path] = { :value => request_path, :expires => 7.days.from_now }
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

  def rescue_action(e)
    if e.to_s =~ /^\d+$/
      status = e.to_s.to_i
      file = error_html_file(status)
      return ss_send_file(file, status: status, type: Fs.content_type(file), disposition: :inline)
    end
    raise e
  end

  def error_html_file(status)
    file = "#{Rails.public_path}/#{status}.html"
    Fs.exists?(file) ? file : "#{Rails.public_path}/500.html"
  end
end
