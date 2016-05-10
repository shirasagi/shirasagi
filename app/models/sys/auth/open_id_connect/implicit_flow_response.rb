class Sys::Auth::OpenIdConnect::ImplicitFlowResponse
  include ActiveModel::Model

  attr_accessor :state
  attr_accessor :id_token

  attr_accessor :cur_item
  attr_accessor :session_state
  attr_accessor :session_nonce

  validates :state, presence: true
  validates :id_token, presence: true

  validates :cur_item, presence: true
  validates :session_state, presence: true
  validates :session_nonce, presence: true

  validate :validate_state
  validates_with Sys::Auth::OpenIdConnect::JwtValidator

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
      errors.add :state, :mismatch if state != session_state
    end
end
