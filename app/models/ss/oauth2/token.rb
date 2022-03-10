class SS::OAuth2::Token
  include SS::Document
  include SS::Reference::User

  field :token, type: String
  field :scopes, type: SS::Extensions::Words
  field :expiration_date, type: DateTime

  validates :user_id, presence: true
  validates :token, presence: true, uniqueness: true
  validates :expiration_date, presence: true

  class << self
    def new_token(user, scopes)
      new(cur_user: user, user: user, token: SecureRandom.urlsafe_base64(12), scopes: scopes, expiration_date: 1.hour.from_now)
    end

    def create_token!(user, scopes)
      ret = new_token(user, scopes)
      ret.save!
      ret
    end

    def and_token(token)
      all.where(token: token.to_s)
    end
  end

  def enabled?(now = nil)
    return false if expiration_date.blank?

    now ||= Time.zone.now
    expiration_date > now
  end
end
