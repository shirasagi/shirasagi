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
    raise "404" if Sys::Auth::Setting.instance.mfa_use?

    login
    render :login if response.body.blank?
  end

  def status
    if @cur_user = SS.current_user = get_user_by_session
      SS.change_locale_and_timezone(SS.current_user)
      render plain: 'OK'
    else
      # to suppress error level log directly responds "forbidden"
      head :forbidden
    end
  end
end
