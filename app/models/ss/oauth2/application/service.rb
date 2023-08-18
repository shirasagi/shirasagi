class SS::OAuth2::Application::Service < SS::OAuth2::Application::Base
  include SS::Reference::User

  attr_accessor :in_public_key

  field :public_key_type, type: String
  field :public_key_encrypted, type: String

  before_validation :encrypt_public_key

  validates :public_key_type, presence: true, inclusion: { in: %w(rsa), allow_blank: true }
  validates :public_key_encrypted, presence: true

  permit_params :in_public_key

  def public_key
    public_key = SS::Crypto.decrypt(public_key_encrypted)
    OpenSSL::PKey::RSA.new(public_key)
  end

  def public_key_finger_print
    return nil if public_key_encrypted.blank?
    OpenSSL::Digest::SHA1.hexdigest(public_key.to_der).scan(/../).join(':')
  end

  private

  def encrypt_public_key
    return if in_public_key.blank?

    begin
      key = OpenSSL::PKey::RSA.new(in_public_key) do
        nil
      end
    rescue OpenSSL::OpenSSLError => e
      Rails.logger.info("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    end
    return if key.blank?

    if key.private?
      # extract public key
      key = key.public_key
    end

    self.public_key_type = "rsa"
    self.public_key_encrypted = SS::Crypto.encrypt(key.to_pem)
  end
end
