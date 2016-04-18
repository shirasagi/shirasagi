# Remember me token
# see:
#   http://stackoverflow.com/questions/244882/what-is-the-best-way-to-implement-remember-me-for-a-website
#   https://paragonie.com/blog/2015/04/secure-authentication-php-with-long-term-persistence#title.2
class SS::UserToken
  include SS::Document
  include SS::Reference::User

  seqid :id
  field :token, type: String
  field :expires, type: DateTime

  attr_accessor :out_token

  before_validation :set_token
  before_validation :set_expires

  # set TTL index
  index({ updated: 1 }, { expire_after_seconds: 2.weeks })

  class << self
    def find_user_by_cookie(cookie)
      return if cookie.blank?

      id, token = cookie.split(':')
      return if id.blank?
      return if token.blank?

      user_token = SS::UserToken.find(id) rescue nil
      return if user_token.blank?

      token = [ token ].pack("H*")
      token = Digest::SHA256.hexdigest(token)
      if user_token.token == token
        user = user_token.user
        user_token.destroy
        return user
      end

      # remember me session is theft.
      SS::UserToken.where(user_id: user_token.user_id).destroy_all
      nil
    end
  end

  def cookie_value
    "#{id}:#{out_token}"
  end

  private
    def set_token
      self.token ||= begin
        random = SecureRandom.random_bytes(32)
        self.out_token = random.unpack("H*")[0]
        Digest::SHA256.hexdigest(random)
      end
    end

    def set_expires
      self.expires ||= 2.weeks.from_now
    end
end
