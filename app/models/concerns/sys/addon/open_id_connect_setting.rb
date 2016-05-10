module Sys::Addon
  module OpenIdConnectSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :issuer, type: String
      field :auth_url, type: String
      field :token_url, type: String
      field :client_id, type: String
      field :client_secret, type: String
      field :response_type, type: String, default: ->{ default_response_type }
      field :scope, type: String, default: ->{ default_scope }
      field :max_age, type: Integer
      field :claims, type: SS::Extensions::Words, default: ->{ default_claims }
      field :response_mode, type: String
      field :jwks_uri, type: String
      embeds_many :jwks, class_name: "Sys::Auth::OpenIdConnect::JsonWebKey"
      attr_accessor :in_client_secret, :rm_client_secret
      permit_params :issuer, :auth_url, :token_url, :client_id, :client_secret, :response_type
      permit_params :scope, :max_age, :claims, :response_mode, :jwks_uri
      permit_params :in_client_secret
      before_validation :set_client_secret, if: ->{ in_client_secret }
      before_validation :reset_client_secret, if: ->{ rm_client_secret }
    end

    def redirect_uri(host)
      Rails.application.routes.url_helpers.sns_login_open_id_connect_callback_url(host: host, id: filename)
    end

    def default_response_type
      "id_token"
    end

    def default_scope
      "openid"
    end

    def default_claims
      %w(email sub)
    end

    def response_mode_options
      %w(form_post).map do |v|
        [ v, v ]
      end
    end

    def code_flow?
      (response_type.presence || default_response_type).include?('code')
    end

    def implicit_flow?
      (response_type.presence || default_response_type).include?('id_token')
    end

    def update_jwks!
      return if jwks_uri.blank?

      http_client = Faraday.new(url: jwks_uri) do |builder|
        builder.request  :url_encoded
        builder.response :logger, Rails.logger
        builder.adapter Faraday.default_adapter
      end
      http_client.headers[:user_agent] += " (SHIRASAGI/#{SS.version}; PID/#{Process.pid})"
      jwks_resp = http_client.get
      return false unless jwks_resp.status != 200 || json?(jwks_resp.headers['Content-Type'])

      jwks_json = JSON.parse(jwks_resp.body)
      self.jwks.destroy_all
      jwks_json['keys'].each do |jwk_json|
        self.jwks.create(
          kty: jwk_json['kty'],
          alg: jwk_json['alg'],
          kid: jwk_json['kid'],
          others: jwk_json.except('kty', 'alg', 'kid'))
      end
    end

    private
      def set_client_secret
        self.client_secret = SS::Crypt.encrypt(in_client_secret)
      end

      def reset_client_secret
        self.client_secret = nil
      end

      def json?(content_type)
        return false if content_type.blank?
        content_type.include?('application/json') || content_type.include?('text/json')
      end
  end
end
