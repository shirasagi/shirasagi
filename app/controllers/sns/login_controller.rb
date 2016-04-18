class Sns::LoginController < ApplicationController
  include Sns::BaseFilter

  protect_from_forgery except: :remote_login
  skip_before_action :verify_authenticity_token unless SS.config.env.protect_csrf
  skip_action_callback :logged_in?, only: [:login, :remote_login]

  layout "ss/login"
  navi_view nil

  private
    def get_params
      params.require(:item).permit(:uid, :email, :password, :encryption_type, :remember_me)
    rescue
      raise "400"
    end

    def login_success
      if params[:ref].blank?
        redirect_to SS.config.sns.logged_in_page
      elsif params[:ref] =~ /^\//
        redirect_to params[:ref]
      else
        render :redirect
      end
    end

  public
    def login
      if !request.post?
        if user = SS::UserToken.find_user_by_cookie(cookies[SS.config.sns.remember_me_key])
          set_user user, session: true, remember_me: true
          respond_to do |format|
            format.html { login_success }
            format.json { head :no_content }
          end
          return
        end

        # retrieve parameters from get parameter. this is bookmark support.
        @item = SS::LoginParam.new email: params[:email]
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

      if @item
        set_user @item, session: true, password: password, remember_me: safe_params[:remember_me] == 'yes'
        respond_to do |format|
          format.html { login_success }
          format.json { head :no_content }
        end
      else
        @item = SS::LoginParam.new email: email_or_uid
        @error = t "sns.errors.invalid_login"
        respond_to do |format|
          format.html { render }
          format.json { render json: @error, status: :unprocessable_entity }
        end
      end
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
      # delete remember me token
      cookies.delete(SS.config.sns.remember_me_key)

      respond_to do |format|
        format.html { redirect_to sns_login_path }
        format.json { head :no_content }
      end
    end
end
