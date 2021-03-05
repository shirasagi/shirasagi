module Service::BaseFilter
  extend ActiveSupport::Concern
  include Service::AuthFilter
  include SS::LayoutFilter

  included do
    cattr_accessor(:user_class) { Service::Account }
    cattr_accessor :model_class
    before_action :set_model
    before_action :set_ss_assets
    before_action :logged_in?
    before_action :set_crumbs
    rescue_from RuntimeError, with: :rescue_action
    layout "service/base"
    navi_view "service/main/navi"
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

  def set_crumbs
    # extend
  end

  def set_ss_assets
    SS.config.ss.stylesheets.each { |m| stylesheet(m) } if SS.config.ss.stylesheets.present?
    SS.config.ss.javascripts.each { |m| javascript(m) } if SS.config.ss.javascripts.present?
    stylesheet("/assets/css/colorbox/colorbox.css")
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

    respond_to do |format|
      format.html { redirect_to service_login_path }
      format.json { render json: :error, status: :unauthorized }
    end
  end

  def set_user(user, opts = {})
    if opts[:session]
      reset_session
      session[:service_account] = {
        "user_id" => user.id,
        "remote_addr" => remote_addr,
        "user_agent" => request.user_agent,
        "last_logged_in" => Time.zone.now.to_i
      }
      if opts[:password].present?
        session[:service_account]["password"] = SS::Crypt.encrypt(opts[:password])
      end
    end
    redirect_to service_main_path if opts[:redirect]
    @cur_user = user
  end

  def rescue_action(exception)
    if exception.to_s.numeric?
      status = exception.to_s.to_i
      file = error_html_file(status)
      return ss_send_file(file, status: status, type: Fs.content_type(file), disposition: :inline)
    end
    raise exception
  end

  def error_html_file(status)
    file = "#{Rails.public_path}/.error_pages/#{status}.html"
    Fs.exists?(file) ? file : "#{Rails.public_path}/.error_pages/500.html"
  end
end
