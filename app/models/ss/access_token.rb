class SS::AccessToken
  include SS::Document
  include SS::Reference::User

  field :token, type: String
  field :expiration_date, type: DateTime
  field :login_path, type: String
  field :logout_path, type: String

  validates :user_id, presence: true
  validates :token, presence: true, uniqueness: true
  validates :expiration_date, presence: true

  scope :and_token, ->(token) {
    where token: token.to_s
  }

  def enabled?
    return false if expiration_date.blank?

    expiration_date > Time.zone.now
  end

  def create_token
    self.token = SecureRandom.urlsafe_base64(12)
    self.expiration_date = 5.minutes.from_now
  end
end
