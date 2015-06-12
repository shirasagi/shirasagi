module Member::LoginFilter
  extend ActiveSupport::Concern

  REDIRECT_OPTION_UNDEFINED = 0.freeze
  REDIRECT_OPTION_ENABLED = 1.freeze
  REDIRECT_OPTION_DISABLED = 2.freeze

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

      clear_member
      return nil if translate_redirect_option(opts) == REDIRECT_OPTION_DISABLED

      ref = "?ref=#{CGI.escape(request.env["REQUEST_URI"])}" if request.env["REQUEST_URI"].present?
      redirect_to "#{member_login_path}#{ref}"
      nil
    end

    def set_member(member)
      session[:member] = SS::Crypt.encrypt("#{member._id},#{remote_addr},#{request.user_agent}")
      @cur_member = member
    end

    def clear_member
      session[:member] = nil
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
      return "/" unless member_login_node
      member_login_node.redirect_url || "/"
    end

    def translate_redirect_option(opts)
      case opts[:redirect]
      when true
        REDIRECT_OPTION_ENABLED
      when false
        REDIRECT_OPTION_DISABLED
      else
        REDIRECT_OPTION_UNDEFINED
      end
    end
end
