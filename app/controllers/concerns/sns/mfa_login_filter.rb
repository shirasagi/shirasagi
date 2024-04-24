module Sns::MFALoginFilter
  extend ActiveSupport::Concern
  include Sns::LoginFilter

  included do
    skip_before_action :logged_in?
    prepend_view_path "app/views/sns/mfa_login"
    layout "ss/login"
    navi_view nil
    helper_method :ref, :otp_secret, :otp_qr_code
  end

  private

  def application_name
    @application_name ||= @cur_site.try(:name) || SS.config.ss.application_name
  end

  def otp_secret
    @otp_secret ||= begin
      # セッションが同じ限りシークレットは同じとする。つまり、アプリの再登録は不要とする。
      # セキュリティが低下する懸念はあるが、ログインの敷居を下げたい。
      session[:authenticated_in_1st_step][:otp_secret] ||= ROTP::Base32.random
    end
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
    @item = self.user_class.find(session[:authenticated_in_1st_step][:user_id])

    render template: "login"
  end

  def otp_login
    raise "404" if session[:authenticated_in_1st_step].blank? || session[:authenticated_in_1st_step][:user_id].blank?
    @item = self.user_class.find(session[:authenticated_in_1st_step][:user_id])

    safe_params = params.require(:item).permit(:code)

    totp = ROTP::TOTP.new(@item.mfa_otp_secret, issuer: application_name)
    result = totp.verify(safe_params[:code], drift_behind: 15)
    unless result
      @item.errors.add :base, :mfa_otp_code_verification_is_failed
      render template: "login"
      return
    end

    render_login(
      @item, nil, session: true, **session[:authenticated_in_1st_step].slice(:password, :login_path, :logout_path))
  end

  def otp_setup
    raise "404" if session[:authenticated_in_1st_step].blank? || session[:authenticated_in_1st_step][:user_id].blank?
    @item = self.user_class.find(session[:authenticated_in_1st_step][:user_id])

    safe_params = params.require(:item).permit(:otp_secret, :code)
    totp = ROTP::TOTP.new(safe_params[:otp_secret], issuer: application_name)

    result = totp.verify(safe_params[:code], drift_behind: 15)
    if result
      @item.set(mfa_otp_secret: safe_params[:otp_secret], mfa_otp_enabled_at: Time.zone.now)

      render_login(
        @item, nil, session: true, **session[:authenticated_in_1st_step].slice(:password, :login_path, :logout_path))
      return
    end

    @item.errors.add :base, :mfa_otp_code_verification_is_failed
    render template: "login"
  end
end
