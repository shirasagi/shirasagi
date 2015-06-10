module Member::LoginFilter
  extend ActiveSupport::Concern

  included do
    before_action :logged_in?, if: -> { member_login_path }
  end

  private
    def remote_addr
      request.env["HTTP_X_REAL_IP"] || request.remote_addr
    end

    def logged_in?(opts = {})
      return @cur_member if @cur_member

      if session[:member]
        u = SS::Crypt.decrypt(session[:member]).to_s.split(",", 3)
        # return unset_member redirect: true if u[1] != remote_addr
        # return unset_member redirect: true if u[2] != request.user_agent.to_s
        @cur_member = Cms::Member.site(@cur_site).find u[0].to_i rescue nil
      end

      return @cur_member if @cur_member
      unset_member

      ref = "?ref=#{CGI.escape(request.env["REQUEST_URI"])}"
      redirect_to "#{member_login_path}#{ref}"
    end

    def set_member(member, opt = {})
      if opt[:session]
        session[:member] = SS::Crypt.encrypt("#{member._id},#{remote_addr},#{request.user_agent}")
      end
      redirect_to redirect_url if opt[:redirect]
      @cur_member = member
    end

    def unset_member(opt = {})
      session[:member] = nil
      redirect_to member_login_path if opt[:redirect]
      @cur_member = nil
    end

    def member_login_node
      @member_login_node ||= begin
        node = Member::Node::Login.site(@cur_site).public.first
        node.present? ? node : false
      end
    end

    def member_login_path
      return false unless member_login_node
      "#{member_login_node.url}login.html"
    end

    def redirect_url
      return false unless member_login_node
      member_login_node.redirect_url || "/"
    end
end
