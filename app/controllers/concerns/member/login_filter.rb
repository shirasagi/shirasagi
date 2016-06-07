module Member::LoginFilter
  extend ActiveSupport::Concern
  include Member::AuthFilter

  REDIRECT_OPTION_UNDEFINED = 0
  REDIRECT_OPTION_ENABLED = 1
  REDIRECT_OPTION_DISABLED = 2

  included do
    # before_action :logged_in?, if: -> { member_login_path }
    before_action :logged_in?
  end

  private
    def remote_addr
      request.env["HTTP_X_REAL_IP"] || request.remote_addr
    end

    def logged_in?(opts = {})
      return @cur_member if @cur_member
      @cur_member = get_member_by_session(@cur_site)
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
        node = Member::Node::Login.site(@cur_site).and_public.first
        node.present? ? node : false
      end
    end

    def member_login_path
      raise "404" unless member_login_node
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
