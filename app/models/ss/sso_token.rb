class SS::SsoToken
  include SS::Document

  field :token, type: String
  field :ref, type: String
  field :login_path, type: String

  validates :token, presence: true, uniqueness: true

  class << self
    def new_token(extra_attrs = nil)
      attr = { token: SecureRandom.urlsafe_base64(12) }
      attr.merge!(extra_attrs) if extra_attrs.present?

      self.new(attr)
    end

    def create_token!(extra_attrs = nil)
      token = new_token(extra_attrs)
      token.save!
      token
    end
  end
end
