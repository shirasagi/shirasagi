module Service::AuthFilter
  extend ActiveSupport::Concern

  def get_user_by_session
    session_user = session[:service_account]
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
    end_of_session_time = last_logged_in + SS.config.sns.session_lifetime
    return nil if Time.zone.now.to_i > end_of_session_time

    user
  end

  def set_last_logged_in(timestamp = Time.zone.now.to_i)
    session[:service_account]["last_logged_in"] = timestamp if session[:service_account]
  end

  def unset_user(opt = {})
    session[:service_account] = nil
    redirect_to service_login_path if opt[:redirect]
    @cur_user = SS.current_user = nil
    SS.current_permission_mask = nil
  end
end
