class Member::Agents::Nodes::LoginController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter

  class OAuthBuilder < ::OmniAuth::Builder
    attr_accessor :cur_site, :cur_node, :cur_date

    def initialize(default_app, cur_site, cur_node, cur_date, &block)
      @cur_site = cur_site
      @cur_node = cur_node
      @cur_date = cur_date
      super(default_app, &block)
    end
  end

  skip_before_action :logged_in?, only: [:login, :logout, :init, :callback, :failure]
  around_action :execute_action_within_omni_auth

  private

  def build_middleware(klass, *args, &block)
    ActionDispatch::MiddlewareStack::Middleware.new(klass, args, block)
  end

  def execute_action_within_omni_auth(*_args, &block)
    middleware = build_middleware OAuthBuilder, @cur_site, @cur_node, @cur_date do
      configure do |config|
        config.logger = Rails.logger
        prefix = @cur_node.url
        prefix = prefix[0..-2] if prefix.end_with?("/")
        config.path_prefix = prefix
      end
      on_failure do |env|
        new_path = env["omniauth.origin"].presence
        new_path ||= @cur_node.try(:full_url)
        new_path ||= "/"
        Rack::Response.new(['302 Moved'], 302, 'Location' => new_path).finish
      end

      Cms::Member::OAUTH_PROVIDERS.each do |oauth_provider|
        if @cur_node.send("#{oauth_provider}_oauth") == "enabled"
          klass, *args = @cur_node.send("#{oauth_provider}_oauth_strategy")
          provider klass, *args
        end
      end
    end

    available = %i[twitter twitter2 facebook yahoojp yahoojp_v2 google_oauth2 github line].any? do |type|
      @cur_node.send("#{type}_oauth") == "enabled"
    end
    unless available
      # no oauth is available.
      return yield
    end

    builder = middleware.build(block)
    rack_app = builder.to_app

    status, headers, body = rack_app.call(request.env)
    if status.present?
      # OmniAuth が応答する場合と Member::Agents::Nodes::LoginController が応答する場合とがある。
      # OmniAuth が応答した場合、Rack レスポンスが生成されるので status が nil 以外になる。
      # Member::Agents::Nodes::LoginController が応答した場合、status が nil になる。
      #
      # OmniAuth が応答した場合、response オブジェクトに応答がセットされていないので、セットしてやる
      response.status = status
      if headers.present?
        headers.each do |key, value|
          response.headers[key] = value
        end
      end
      if body.present?
        response.body = body
      end
    end
  end

  def get_params
    params.require(:item).permit(:email, :password)
  rescue
    raise "400"
  end

  def set_member_and_redirect(member, notice: nil)
    ref = @cur_node.make_trusted_full_url(params[:ref] || flash[:ref])
    ref = @cur_node.redirect_full_url if ref.blank?
    ref = @cur_site.full_url if ref.blank?
    flash.discard(:ref)

    set_member member
    member.update(last_loggedin: Time.zone.now)
    Member::ActivityLog.create(
      cur_site: @cur_site,
      cur_member: member,
      activity_type: "login",
      remote_addr: remote_addr,
      user_agent: request.user_agent)

    redirect_to ref, notice: notice
  end

  public

  def login
    @item = Cms::Member.new
    unless request.post?
      @error = flash[:alert]
      flash[:ref] = params[:ref]
      return
    end

    @item.attributes = get_params
    member = Cms::Member.site(@cur_site).and_enabled.where(email: @item.email, password: SS::Crypto.crypt(@item.password)).first
    unless member
      @error = t "sns.errors.invalid_login"
      return
    end

    set_member_and_redirect member
  end

  def logout
    # discard all session info
    reset_session if SS.config.sns.logged_in_reset_session
    flash.discard(:ref)
    redirect_to member_login_path
  end

  def init
    head :not_found
  end

  def callback
    auth = request.env["omniauth.auth"]
    member = Cms::Member.unscoped.site(@cur_site).where(oauth_type: auth.provider, oauth_id: auth.uid).first
    if member.blank?
      # 外部認証していない場合、ログイン情報を保存してから、ログインさせる
      Cms::Member.create_auth_member(auth, @cur_site)
      member = Cms::Member.site(@cur_site).and_enabled.where(oauth_type: auth.provider, oauth_id: auth.uid).first
      created = true
    else
      # auth info の名前が変わっていたら上書きする
      name = Cms::Member.name_of(auth.info)
      member.name = name if member.name != name

      # 無効状態の場合は有効にする
      member.state = "enabled" if !member.enabled?
      member.update if member.changed?
    end

    set_member_and_redirect member, notice: created ? I18n.t('member.notice.member_created') : nil
  end

  def failure
    session[:auth_site] = nil
    session[session_member_key] = nil
    flash.discard(:ref)

    redirect_to "#{@cur_node.url}/login.html"
  end
end
