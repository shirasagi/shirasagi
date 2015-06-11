module SS::BaseFilter
  extend ActiveSupport::Concern
  include SS::LayoutFilter
  include History::LogFilter

  included do
    cattr_accessor(:user_class) { SS::User }
    cattr_accessor :model_class

    helper EditorHelper
    before_action :set_model
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

  public
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

    def logged_in?
      return @cur_user if @cur_user

      if session[:user]
        u = SS::Crypt.decrypt(session[:user]).to_s.split(",", 3)
        #return unset_user redirect: true if u[1] != remote_addr.to_s
        #return unset_user redirect: true if u[2] != request.user_agent.to_s
        @cur_user = self.user_class.find u[0].to_i rescue nil
      end

      return @cur_user if @cur_user
      unset_user

      ref = request.env["REQUEST_URI"]
      ref = (ref == sns_mypage_path) ? "" : "?ref=" + CGI.escape(ref.to_s)
      redirect_to "#{sns_login_path}#{ref}"
    end

    def set_user(user, opt = {})
      if opt[:session]
        session[:user] = SS::Crypt.encrypt("#{user._id},#{remote_addr},#{request.user_agent}")
        session[:password] = SS::Crypt.encrypt(opt[:password]) if opt[:password].present?
      end
      redirect_to sns_mypage_path if opt[:redirect]
      @cur_user = user
    end

    def unset_user(opt = {})
      session[:user] = nil
      session[:password] = nil
      redirect_to sns_login_path if opt[:redirect]
      @cur_user = nil
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
