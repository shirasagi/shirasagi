class Sys::Auth::OpenIdConnect::TokenResponse
  include ActiveModel::Model

  attr_accessor :access_token
  attr_accessor :token_type
  attr_accessor :refresh_token
  attr_accessor :expires_in
  attr_accessor :id_token
  attr_accessor :error
  attr_accessor :error_description
  attr_accessor :error_uri

  attr_accessor :cur_item
  attr_accessor :session_nonce

  validates :id_token, presence: true

  validates :cur_item, presence: true
  validates :session_nonce, presence: true

  validates_with Sys::Auth::OpenIdConnect::JwtValidator

  def jwt
    return nil if id_token.blank?
    @jwt ||= JSON::JWT.decode(id_token, :skip_verification)
  end
end
