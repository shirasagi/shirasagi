class Sys::Auth::OpenIdConnect::ImplicitFlowResponse
  include ActiveModel::Model

  attr_accessor :state, :id_token, :cur_item, :sso_token, :session_nonce

  validates :state, presence: true
  validates :id_token, presence: true

  validates :cur_item, presence: true
  validates :sso_token, presence: true
  validates :session_nonce, presence: true

  validate :validate_state
  validates_with Sys::Auth::OpenIdConnect::JWTValidator

  def id
    claim = (cur_item.claims.presence || cur_item.default_claims).find { |claim| jwt[claim].present? }
    jwt[claim]
  end

  def jwt
    return nil if id_token.blank?
    @jwt ||= JSON::JWT.decode(id_token, :skip_verification)
  end

  private

  def validate_state
    return if state.blank? || sso_token.blank?

    errors.add :state, :mismatch if state != sso_token.token
    errors.add :state, :expired unless sso_token.available?
  end
end
