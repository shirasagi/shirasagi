class Sys::Auth::OpenIdConnect::TokenResponse
  include ActiveModel::Model

  attr_accessor :access_token, :token_type, :refresh_token, :expires_in, :id_token, :error, :error_description, :error_uri, :cur_item, :sso_token, :session_nonce

  validates :id_token, presence: true

  validates :cur_item, presence: true
  validates :sso_token, presence: true
  validates :session_nonce, presence: true

  validates_with Sys::Auth::OpenIdConnect::JWTValidator

  def id
    claim = (cur_item.claims.presence || cur_item.default_claims).find { |claim| jwt[claim].present? }
    jwt[claim]
  end

  def jwt
    return nil if id_token.blank?
    @jwt ||= JSON::JWT.decode(id_token, :skip_verification)
  end
end
