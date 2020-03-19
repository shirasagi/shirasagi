require 'json/jwt'

class Sns::Login::OpenIdConnectController < ApplicationController
  include Sns::BaseFilter
  include Sns::LoginFilter

  skip_before_action :logged_in?
  before_action :set_item

  model Sys::Auth::OpenIdConnect

  layout "ss/login"
  navi_view nil

  private

  def set_item
    @item ||= @model.find_by(filename: params[:id])
  end

  def nonce
    @nonce ||= begin
      nonce = SecureRandom.hex(24)
      session['ss.sso.nonce'] = nonce
      nonce
    end
  end

  def state
    @state ||= begin
      state = SecureRandom.hex(24)
      session['ss.sso.state'] = state
      state
    end
  end

  def authorization_code_flow_callback
    core_resp = params.permit(:state, :code, :error, :error_description)
    if core_resp[:error]
      Rails.logger.warn("#{core_resp[:error]}:#{core_resp[:error_description]}")
      raise "403"
    end

    auth_resp = core_resp.merge(
      cur_item: @item,
      redirect_uri: @item.redirect_uri(request.host_with_port),
      session_state: session.delete('ss.sso.state'))
    token_req = Sys::Auth::OpenIdConnect::TokenRequest.new(auth_resp)
    if token_req.invalid?
      Rails.logger.warn(token_req.errors.full_messages.join("\n"))
      raise "403"
    end

    @resp = token_req.execute
    @resp.session_nonce = session.delete('ss.sso.nonce')
    if @resp.invalid?
      Rails.logger.warn(@resp.errors.full_messages.join("\n"))
      raise "403"
    end
  end

  def implicit_flow_callback
    core_resp = params.permit(:state, :id_token, :error, :error_description)
    if core_resp[:error]
      Rails.logger.warn("#{core_resp[:error]}:#{core_resp[:error_description]}")
      raise "403"
    end

    if request.get? && core_resp.blank?
      render file: 'sns/login/open_id_connect/implicit_flow_post_back', layout: false
      return
    end

    auth_resp = core_resp.merge(
      cur_item: @item,
      session_state: session.delete('ss.sso.state'),
      session_nonce: session.delete('ss.sso.nonce'))
    @resp = Sys::Auth::OpenIdConnect::ImplicitFlowResponse.new(auth_resp)
    unless @resp.valid?
      Rails.logger.warn(@resp.errors.full_messages.join("\n"))
      raise "403"
    end
  end

  public

  def init
    params = {
      client_id: @item.client_id,
      # redirect_uri: "http://#{request.host_with_port}/.mypage/login/oid/#{@item.filename}/callback",
      redirect_uri: @item.redirect_uri(request.host_with_port),
      response_type: @item.response_type || @item.default_response_type,
      nonce: nonce,
      scope: @item.scopes.join(" ") || @item.default_scopes.join(" "),
      state: state
    }
    params[:max_age] = @item.max_age if @item.max_age.present?
    params[:response_mode] = @item.response_mode if @item.response_mode.present?
    url = "#{@item.auth_url}?#{params.to_query}"
    redirect_to url
  end

  def callback
    if @item.code_flow?
      authorization_code_flow_callback
    elsif @item.implicit_flow?
      implicit_flow_callback
    else
      raise "404"
    end

    return unless @resp

    user = SS::User.uid_or_email(@resp.id).and_enabled.and_unlocked.first
    if user.blank?
      Rails.logger.info("#{@resp.id}: user not found")
      render_login nil, nil
      return
    end

    render_login user, nil, session: true, login_path: sns_login_path
  end

  if Rails.env.test?
    #
    # mock methods for test
    #
    def implicit
      redirect_uri = URI.parse(params[:redirect_uri].to_s)
      claims = {
        # required claims
        iss: @item.issuer,
        sub: @item.filename,
        aud: @item.client_id,
        exp: (Time.zone.now + 1.hour).to_i,
        iat: Time.zone.now.to_i,
        nonce: params[:nonce],
        # optional claims to identify user
        email: @item.text.try { |s| s.strip }
      }
      id_token = JSON::JWT.new(claims)
      id_token = id_token.sign(SS::Crypt.decrypt(@item.client_secret))

      resp = {
        id_token: id_token.to_s,
        state: params[:state]
      }
      redirect_to "#{redirect_uri}?#{resp.to_query}"
    end

    cattr_accessor :last_nonce

    def authorization_code
      redirect_uri = URI.parse(params[:redirect_uri].to_s)
      self.class.last_nonce = params[:nonce]
      resp = {
        code: SecureRandom.hex(24),
        state: params[:state]
      }
      redirect_to "#{redirect_uri}?#{resp.to_query}"
    end

    def authorization_token
      claims = {
        # required claims
        iss: @item.issuer,
        sub: @item.filename,
        aud: @item.client_id,
        exp: (Time.zone.now + 1.hour).to_i,
        iat: Time.zone.now.to_i,
        nonce: self.class.last_nonce,
        # optional claims to identify user
        email: @item.text.try { |s| s.strip }
      }
      id_token = JSON::JWT.new(claims)
      id_token = id_token.sign(SS::Crypt.decrypt(@item.client_secret))

      resp = {
        access_token: SecureRandom.hex(24),
        token_type: "Bearer",
        refresh_token: SecureRandom.hex(24),
        expires_in: 3600,
        id_token: id_token.to_s
      }

      render json: resp, status: :ok
    end
  end
end
