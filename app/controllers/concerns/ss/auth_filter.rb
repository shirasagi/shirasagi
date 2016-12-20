module SS::AuthFilter
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:user_class) { SS::User }
  end

  def user_session_alives?(timestamp = Time.zone.now.to_i)
    session[:user] && timestamp <= session[:user]["last_logged_in"] + SS.config.sns.session_lifetime
  end

  def get_user_by_session
    return nil unless user_session_alives?

    user_id = session[:user]["user_id"]
    user = self.user_class.find(user_id) rescue nil
    if user
      user.decrypted_password = SS::Crypt.decrypt(session[:user]["password"])
      user = nil unless user.enabled?
    end
    user
  end

  def set_last_logged_in(timestamp = Time.zone.now.to_i)
    session[:user]["last_logged_in"] = timestamp if session[:user]
  end

  def unset_user(opt = {})
    session[:user] = nil
    redirect_to sns_login_path if opt[:redirect]
    @cur_user = nil
  end
end
