class SS::ApiToken
  include SS::Document
  include SS::Reference::User

  API_KEY_HEADER = "X-SS-API-Key".freeze

  field :name, type: String
  field :subject, type: String, default: nil
  field :jwt_id, type: String, default: -> { SecureRandom.uuid }
  field :expiration_date, type: DateTime, default: nil
  field :custom_claim, type: Hash, default: {}
  field :state, type: String, default: "public"
  belongs_to :audience, class_name: "SS::User"

  permit_params :name, :expiration_date, :state, :audience_id

  validates :name, presence: true
  validates :user_id, presence: true
  validates :jwt_id, presence: true
  validates :audience_id, presence: true

  default_scope -> { order_by(created: -1) }

  def sub
    subject
  end

  def jti
    jwt_id
  end

  def aud
    return unless audience
    audience.id.to_s
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
    return unless expiration_date
    created.to_i
  end

  def to_jwt
    payload = { iss: iss, sub: sub, aud: aud, exp: exp,
      nbf: nbf, iat: iat, jti: jti }
    payload.merge!(custom_claim).compact!
    JWT.encode payload, self.class.secret, 'HS256'
  end

  def state_options
    %w(public closed).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }
  end

  def public?
    state == "public"
  end

  def closed?
    !public?
  end

  def expiration_date_label
    expiration_date ? I18n.l(expiration_date, format: :picker) : I18n.t("ss.unlimited")
  end

  class << self
    def iss
      nil
    end

    def secret
      Rails.application.secrets[:secret_key_base][0..31]
    end

    def get_token(request)
      token = request.headers[SS::ApiToken::API_KEY_HEADER].presence
      token ||= begin
        token_and_options = ActionController::HttpAuthentication::Token.token_and_options(request)
        token_and_options ? token_and_options[0] : nil
      end
      token
    end

    def authenticate(request, opts = {})
      raise "unimplemented!"
    end
  end
end
