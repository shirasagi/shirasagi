module Member::LoginFilter
  extend ActiveSupport::Concern

  REDIRECT_OPTION_UNDEFINED = 0
  REDIRECT_OPTION_ENABLED = 1
  REDIRECT_OPTION_DISABLED = 2

  included do
    before_action :logged_in?, if: -> { member_login_path }
  end

  private
    def remote_addr
      request.env["HTTP_X_REAL_IP"] || request.remote_addr
    end

    def logged_in?(opts = {})
      if @cur_member
        reset_expires_at
        return @cur_member
      end

      if session[:member] && Time.zone.now.to_i < session[:member]["expires_at"]
        member_id = session[:member]["member_id"]
        @cur_member = Cms::Member.site(@cur_site).find(member_id) rescue nil
      end

      if @cur_member
        reset_expires_at
        return @cur_member
      end

      clear_member
      return nil if translate_redirect_option(opts) == REDIRECT_OPTION_DISABLED

      ref = "?ref=#{CGI.escape(request.env["REQUEST_URI"])}" if request.env["REQUEST_URI"].present?
      redirect_to "#{member_login_path}#{ref}"
      nil
    end

    def set_member(member)
      session[:member] = {
        "member_id" => member.id,
        "remote_addr" => remote_addr,
        "user_agent" => request.user_agent,
        "expires_at" => Time.zone.now.to_i + SS.config.cms.session_lifetime }
      @cur_member = member
    end

    def reset_expires_at
      session[:member]["expires_at"] = Time.zone.now.to_i + SS.config.cms.session_lifetime if session[:member]
    end

    def clear_member
      session[:member] = nil
      @cur_member = nil
    end

    def member_login_node
      @member_login_node ||= begin
        node = Member::Node::Login.site(@cur_site).and_public.first
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
