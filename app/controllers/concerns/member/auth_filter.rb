module Member::AuthFilter
  extend ActiveSupport::Concern

  def get_member_by_session(site = false)
    return nil unless session[:member]

    u = SS::Crypt.decrypt(session[:member]).to_s.split(",", 3)
    # return unset_member redirect: true if u[1] != remote_addr
    # return unset_member redirect: true if u[2] != request.user_agent.to_s
    if site == false
      Cms::Member.find u[0].to_i rescue nil
    else
      Cms::Member.site(site).find u[0].to_i rescue nil
    end
  end
end
