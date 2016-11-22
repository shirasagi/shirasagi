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
