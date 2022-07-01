module SS::AuthFilter
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:user_class) { SS::User }
  end

  def sesession_lieftime_of_user(user)
    user.session_lifetime.presence || SS.config.sns.session_lifetime
  end

  def get_user_by_session
    session_user = session[:user]
    return nil if session_user.blank?
    user_id = session_user["user_id"]
    return nil if user_id.blank?
    last_logged_in = session_user["last_logged_in"]
    return nil if last_logged_in.blank?

    # is user_id valid?
    user = self.user_class.find(user_id) rescue nil
    return nil if user.blank?
    return nil if user.disabled?

    # is session expired?
    end_of_session_time = last_logged_in + sesession_lieftime_of_user(user)
    return nil if Time.zone.now.to_i > end_of_session_time

    user.decrypted_password = SS::Crypto.decrypt(session[:user]["password"])
    user
  end

  def get_user_by_access_token
    return nil if params[:access_token].blank?

    token = SS::AccessToken.and_token(params[:access_token]).first
    return nil unless token
    return nil unless token.enabled?

    login_path = token.login_path
    logout_path = token.logout_path
    user = self.user_class.find(token.user_id) rescue nil
    token.destroy
    return nil if user.blank?
    return nil if user.disabled?

    [ user, login_path, logout_path ]
  end

  def get_user_by_oauth2_token
    authenticate_with_http_token do |token, _options|
      token = SS::OAuth2::Token.all.and_token(token).first
      return nil unless token
      return nil unless token.enabled?
      if token.user_id.blank?
        History::Log.create_log!(
          request, response, controller: params[:controller], action: 'token',
          cur_site: nil, cur_user: nil, item: token.application
        ) rescue nil
        return [ nil, token ]
      end

      user = self.user_class.find(token.user_id) rescue nil
      return nil if user.blank?
      return nil if user.disabled?

      History::Log.create_log!(
        request, response, controller: params[:controller], action: 'token',
        cur_site: nil, cur_user: user, item: token.application
      ) rescue nil

      [ user, token ]
    end
  end

  def set_locale_and_timezone
    # I18n.locale = @cur_user.lang.to_sym if @cur_user.try(:lang).present?
    # Time.zone = Time.find_zone(@cur_user.timezone) if @cur_user.try(:timezone).present?
  end

  def set_last_logged_in(timestamp = Time.zone.now.to_i)
    session[:user]["last_logged_in"] = timestamp if session[:user]
  end
end
