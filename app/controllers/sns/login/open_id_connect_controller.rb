require 'json/jwt'

class Sns::Login::OpenIdConnectController < ApplicationController
  include Sns::BaseFilter

  skip_action_callback :logged_in?
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

  public

    def init
      params = {
        client_id: @item.client_id,
        redirect_uri: "http://#{request.host_with_port}/.mypage/sso_login/oid/#{@item.filename}/callback",
        response_type: @item.response_type || @item.default_response_type,
        nonce: nonce,
        scope: @item.scope || @item.default_scope,
        state: state,
      }
      redirect_to "#{@item.auth_url}?#{params.to_query}"
    end

    def callback
      raise "403" if params[:error]

      return if request.get?

      scope = params[:scope]
      state = params[:state]
      id_token = params[:id_token]

      raise "403" if scope.blank? || scope != (@item.scope || @item.default_scope)
      raise "403" if state.blank? || session.delete('ss.sso.state') != state
      raise "403" if id_token.blank?
      Rails.logger.debug("id_token=#{id_token}")

      jwt = JSON::JWT.decode(id_token, SS::Crypt.decrypt(@item.client_secret))
      raise "403" if jwt.typ != "JWT"
      raise "403" if jwt.alg.blank? || jwt.alg == "none"
      raise "403" if jwt["nonce"].blank? || session.delete('ss.sso.nonce') != jwt["nonce"]
      raise "403" if jwt["aud"].blank? || !jwt["aud"].include?(@item.client_id)

      claim = (@item.claims.presence || @item.default_claims).find { |claim| jwt[claim].present? }
      raise "403" if claim.blank?

      render text: jwt[claim], laytout: false
    end
end
