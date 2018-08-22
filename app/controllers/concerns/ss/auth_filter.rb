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
    end_of_session_time = session_user["expired_at"] || last_logged_in + sesession_lieftime_of_user(user)
    return nil if Time.zone.now.to_i > end_of_session_time

    user.decrypted_password = SS::Crypt.decrypt(session[:user]["password"])
    user
  end

  def get_user_by_access_token
    return nil if params[:access_token].blank?
    user = self.class.user_class.where(access_token: params[:access_token].to_s).first
    return nil if !user
    return nil if user.disabled?
    return nil unless user.valid_access_token?
    set_user(user, session: true, expired_at: user.access_token_expiration_date.to_i)
  end

  def set_last_logged_in(timestamp = Time.zone.now.to_i)
    session[:user]["last_logged_in"] = timestamp if session[:user]
  end
end
