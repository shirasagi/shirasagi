module Sys::Addon
  module OpenIdConnectSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :client_id, type: String
      field :client_secret, type: String
      field :issuer, type: String
      field :auth_url, type: String
      field :token_url, type: String
      field :response_type, type: String, default: ->{ default_response_type }
      field :scopes, type: SS::Extensions::Words, default: ->{ default_scopes }
      field :max_age, type: Integer
      field :claims, type: SS::Extensions::Words, default: ->{ default_claims }
      field :response_mode, type: String
      field :jwks_uri, type: String
      embeds_many :jwks, class_name: "Sys::Auth::OpenIdConnect::JsonWebKey"
      attr_accessor :in_discovery_file
      attr_accessor :in_client_secret, :rm_client_secret
      permit_params :issuer, :auth_url, :token_url, :client_id, :client_secret, :response_type
      permit_params :scope, :max_age, :claims, :response_mode, :jwks_uri
      permit_params :in_discovery_file
      permit_params :in_client_secret, :rm_client_secret
      before_validation :load_discovery_file, if: ->{ in_discovery_file }
      before_validation :set_client_secret, if: ->{ in_client_secret }
      before_validation :reset_client_secret, if: ->{ rm_client_secret }
      before_validation :load_discovery_file, if: ->{ in_discovery_file }
    end

    def redirect_uri(host)
      Rails.application.routes.url_helpers.sns_login_open_id_connect_callback_url(host: host, id: filename)
    end

    def default_response_type
      "id_token"
    end

    def default_scopes
      %w(openid email)
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
      def load_discovery_file
        discovery = JSON.parse(in_discovery_file.read)
        self.issuer = discovery['issuer']
        self.auth_url = discovery['authorization_endpoint']
        self.token_url = discovery['token_endpoint']
        self.response_type = discovery['response_types_supported'].find { |x| x.include?(default_response_type) }
        self.scopes = discovery['scopes_supported']
        self.claims = default_claims - discovery['claims_supported']
        self.jwks_uri = discovery['jwks_uri']
      end

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
