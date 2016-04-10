class Sns::LoginController < ApplicationController
  include Sns::BaseFilter
  include Sns::LoginFilter

  protect_from_forgery except: :remote_login
  skip_before_action :verify_authenticity_token unless SS.config.env.protect_csrf
  skip_action_callback :logged_in?, only: [:login, :remote_login]

  layout "ss/login"
  navi_view nil

  private
    def get_params
      params.require(:item).permit(:uid, :email, :password, :encryption_type)
    rescue
      raise "400"
    end

  public
    def login
      if !request.post?
        # retrieve parameters from get parameter. this is bookmark support.
        @item = SS::User.new email: params[:email]
        return
      end

      safe_params     = get_params
      email_or_uid    = safe_params[:email].presence || safe_params[:uid]
      password        = safe_params[:password]
      encryption_type = safe_params[:encryption_type]
      if encryption_type.present?
        password = SS::Crypt.decrypt(password, type: encryption_type) rescue nil
      end

      @item = SS::User.authenticate(email_or_uid, password) rescue false
      @item = nil if @item && !@item.enabled?

      render_login @item, email_or_uid, session: true, password: password
    end

    def remote_login
      raise "404" unless SS::config.sns.remote_login

      login
      render :login if response.body.blank?
    end

    def logout
      put_history_log
      # discard all session info
      reset_session
      respond_to do |format|
        format.html { redirect_to sns_login_path }
        format.json { head :no_content }
      end
    end
end
