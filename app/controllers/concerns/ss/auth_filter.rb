module SS::AuthFilter
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:user_class) { SS::User }
  end

  def get_user_by_session
    return nil unless session[:user]

    u = SS::Crypt.decrypt(session[:user]).to_s.split(",", 3)
    #return unset_user redirect: true if u[1] != remote_addr.to_s
    #return unset_user redirect: true if u[2] != request.user_agent.to_s
    user = self.user_class.find(u[0].to_i) rescue nil
    user = nil unless user.enabled?
    user
  end
end
