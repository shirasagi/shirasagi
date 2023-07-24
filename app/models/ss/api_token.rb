class SS::ApiToken
  include SS::Document
  include SS::Reference::User

  API_KEY_HEADER = "X-SS-API-Key".freeze

  field :name, type: String
  field :subject, type: String, default: nil
  field :jwt_id, type: String, default: -> { SecureRandom.uuid }
  field :expiration_date, type: DateTime, default: nil
  field :not_before_date, type: DateTime, default: nil
  field :custom_claim, type: Hash, default: {}

  permit_params :name, :expiration_date, :not_before_date

  validates :name, presence: true
  validates :user_id, presence: true
  validates :jwt_id, presence: true

  default_scope -> { order_by(created: -1) }

  def sub
    subject
  end

  def jti
    jwt_id
  end

  def aud
    user.id.to_s
  end

  def iss
    nil
  end

  def iat
    created.to_i
  end

  def exp
    return unless expiration_date
    expiration_date.to_i
  end

  def nbf
    return unless not_before_date
    not_before_date.to_i
  end

  def to_jwt
    payload = { iss: iss, sub: sub, aud: aud, exp: exp,
      nbf: nbf, iat: iat, jti: jti }
    payload.merge!(custom_claim).compact!
    JWT.encode payload, self.class.secret, 'HS256'
  end

  class << self
    def iss
      nil
    end

    def secret
      Rails.application.secrets[:secret_key_base][0..31]
    end

    def authenticate(request)
      raise "unimplemented!"
    end
  end
end
