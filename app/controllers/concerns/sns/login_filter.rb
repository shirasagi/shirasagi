module Sns::LoginFilter
  extend ActiveSupport::Concern

  included do
    protect_from_forgery except: :remote_login
    skip_before_action :verify_authenticity_token unless SS.config.env.protect_csrf
    prepend_view_path "app/views/sns/login"
    layout "ss/login"
    navi_view nil
  end

  private

  def remote_login?
    SS::config.sns.remote_login
  end

  def default_logged_in_path
    SS.config.sns.logged_in_page
  end

  def login_success
    if params[:ref].blank?
      redirect_to default_logged_in_path
    elsif params[:ref] =~ /^\/[^\/]/
      redirect_to params[:ref]
    else
      render "sns/login/redirect"
    end
  end

  def render_login(user, email_or_uid, opts = {})
    alert = opts.delete(:alert).presence || t("sns.errors.invalid_login")

    if user
      opts[:session] ||= true
      set_user user, opts

      respond_to do |format|
        format.html { login_success }
        format.json { head :no_content }
      end
    else
      @item = user_class.new
      @item.email = email_or_uid if email_or_uid.present?
      respond_to do |format|
        flash[:alert] = alert
        format.html { render file: :login }
        format.json { render json: alert, status: :unprocessable_entity }
      end
    end
  end

  public

  def logout
    put_history_log
    # discard all session info
    reset_session
    respond_to do |format|
      format.html { redirect_to login_path_by_cookie }
      format.json { head :no_content }
    end
  end
end
