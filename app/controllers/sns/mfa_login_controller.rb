class Sns::MFALoginController < ApplicationController
  include HttpAcceptLanguage::AutoLocale
  include Sns::BaseFilter
  include Sns::LoginFilter

  skip_before_action :logged_in?

  layout "ss/login"
  navi_view nil

  helper_method :ref, :otp_secret, :otp_qr_code

  private

  def application_name
    @application_name ||= @cur_site.try(:name) || SS.config.ss.application_name
  end

  def otp_secret
    @otp_secret ||= ROTP::Base32.random
  end

  def otp_qr_code
    @otp_qr_code ||= begin
      totp = ROTP::TOTP.new(otp_secret, issuer: application_name)
      uri = totp.provisioning_uri(@item.email.presence || @item.name)
      RQRCode::QRCode.new(uri).as_png(resize_exactly_to: 200).to_data_url
    end
  end

  def ref
    session[:authenticated_in_1st_step][:ref] rescue nil
  end

  public

  def login
    raise "404" if session[:authenticated_in_1st_step].blank? || session[:authenticated_in_1st_step][:user_id].blank?
    @item = SS::User.find(session[:authenticated_in_1st_step][:user_id])

    render
  end

  def otp_login
    raise "404" if session[:authenticated_in_1st_step].blank? || session[:authenticated_in_1st_step][:user_id].blank?
    @item = SS::User.find(session[:authenticated_in_1st_step][:user_id])

    safe_params = params.require(:item).permit(:code)

    totp = ROTP::TOTP.new(@item.mfa_otp_secret, issuer: application_name)
    timestamp = totp.verify(safe_params[:code], drift_behind: 15)
    if timestamp
      render_login @item, nil, session: true, password: session[:authenticated_in_1st_step][:password]
    end
  end

  def otp_setup
    raise "404" if session[:authenticated_in_1st_step].blank? || session[:authenticated_in_1st_step][:user_id].blank?
    @item = SS::User.find(session[:authenticated_in_1st_step][:user_id])

    safe_params = params.require(:item).permit(:otp_secret, :code)
    totp = ROTP::TOTP.new(safe_params[:otp_secret], issuer: application_name)

    timestamp = totp.verify(safe_params[:code], drift_behind: 15)
    if timestamp
      @item.set(mfa_otp_secret: safe_params[:otp_secret], mfa_otp_enabled_at: Time.zone.now)

      render_login @item, nil, session: true, password: session[:authenticated_in_1st_step][:password]
      return
    end

    @item.errors.add :base, "入力された確認コードが正しくありません。最初から操作をやり直してください。"
    render template: "login"
  end
end
