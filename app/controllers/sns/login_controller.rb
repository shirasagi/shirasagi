class Sns::LoginController < ApplicationController
  include HttpAcceptLanguage::AutoLocale
  include Sns::BaseFilter
  include Sns::LoginFilter

  skip_before_action :logged_in?, only: [:login, :remote_login, :status, :redirect]

  layout "ss/login"
  navi_view nil

  private

  def get_params
    params.require(:item).permit(:uid, :email, :password, :encryption_type)
  rescue
    raise "400"
  end

  public

  def remote_login
    raise "404" unless SS::config.sns.remote_login
    raise "404" if Sys::Auth::Setting.instance.mfa_otp_use?

    login
    render :login if response.body.blank?
  end

  def status
    @cur_user = SS.current_user = get_user_by_session
    unless @cur_user
      # to suppress error level log directly responds "forbidden"
      head :forbidden
      return
    end

    SS.change_locale_and_timezone(SS.current_user)

    retry_after = remaining_user_session_lifetime
    if retry_after.numeric? && retry_after > 0
      response.headers["Retry-After"] = retry_after + 1
    end
    render plain: 'OK'
  end
end
