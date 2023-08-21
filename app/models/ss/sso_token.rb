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

    def and_unavailable
      all.where(created: { "$lt" => Time.zone.now.to_i - Sys::Auth::Base::READY_STATE_EXPIRES_IN })
    end
  end

  def available?
    created.to_i + Sys::Auth::Base::READY_STATE_EXPIRES_IN >= Time.zone.now.to_i
  end
end
