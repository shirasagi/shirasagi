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
    before_action :set_multilingual_attribute
    before_action :logged_in?
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

    def set_multilingual_attribute
      I18n.locale = I18n.default_locale
      Multilingual::Initializer.lang = nil
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
        return render inline: ''
      end

      ref = request.env["REQUEST_URI"]
      ref = (ref == sns_mypage_path) ? "" : "?ref=" + CGI.escape(ref.to_s)
      respond_to do |format|
        format.html { redirect_to "#{sns_login_path}#{ref}" }
        format.json { render json: :error, status: :unauthorized }
      end
    end

    def set_user(user, opt = {})
      if opt[:session]
        session[:user] = {
          "user_id" => user.id,
          "remote_addr" => remote_addr,
          "user_agent" => request.user_agent,
          "last_logged_in" => Time.zone.now.to_i }
        session[:user]["password"] = SS::Crypt.encrypt(opt[:password]) if opt[:password].present?
      end
      redirect_to sns_mypage_path if opt[:redirect]
      @cur_user = user
    end

    def rescue_action(e)
      if e.to_s =~ /^\d+$/
        status = e.to_s.to_i
        return render status: status, file: error_template(status), layout: false
      end
      raise e
    end

    def error_template(status)
      file = "#{Rails.public_path}/#{status}.html"
      Fs.exists?(file) ? file : "#{Rails.public_path}/500.html"
    end
end
