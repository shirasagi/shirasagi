class Inquiry2::SavedParams
  include SS::Document

  field :data, type: Hash, default: {}
  field :token, type: String
  field :expired_at, type: DateTime

  before_validation :set_token
  validates :data, :token, :expired_at, presence: true

  def set_token
    self.token ||= SecureRandom.uuid
  end

  class << self
    def apply(data, expired_at = nil)
      item = self.new
      item.expired_at = expired_at || Time.zone.now.advance(days: 1)
      item.data = data
      item.save!
      item.token
    end

    def active(date = Time.zone.now)
      self.where({ "expired_at" => { "$gt" => date }})
    end

    def expired(date = Time.zone.now)
      self.where({ "expired_at" => { "$lte" => date }})
    end

    def get(token)
      self.active.where(token: token).first
    end
  end
end
