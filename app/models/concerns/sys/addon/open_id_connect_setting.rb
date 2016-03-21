module Sys::Addon
  module OpenIdConnectSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :auth_url, type: String
      field :token_url, type: String
      field :client_id, type: String
      field :client_secret, type: String
      field :response_type, type: String
      field :scope, type: String
      field :claims, type: SS::Extensions::Words
      attr_accessor :in_client_secret, :rm_client_secret
      permit_params :auth_url, :token_url, :client_id, :client_secret, :response_type, :scope, :claims
      permit_params :in_client_secret
      before_validation :set_client_secret, if: ->{ in_client_secret }
      before_validation :reset_client_secret, if: ->{ rm_client_secret }
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

    private
      def set_client_secret
        self.client_secret = SS::Crypt.encrypt(in_client_secret)
      end

      def reset_client_secret
        self.client_secret = nil
      end
  end
end
