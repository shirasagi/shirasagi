require 'digest/md5'
require 'openssl'
require 'base64'

module SS::Crypto
  @@salt = Rails.application.secret_key_base || "ss-salt"
  DEFAULT_CIPHER_TYPE = "AES-256-CBC".freeze

  class << self
    def salt
      @@salt
    end

    def crypt(str, salt: nil)
      salt ||= @@salt
      Digest::MD5.hexdigest(Digest::MD5.digest(str) + salt)
    end

    def encrypt(str, pass: nil, salt: nil, type: nil)
      pass ||= @@salt
      type ||= DEFAULT_CIPHER_TYPE

      cipher = OpenSSL::Cipher.new type
      cipher.encrypt
      cipher.pkcs5_keyivgen pass, salt
      Base64.strict_encode64(cipher.update(str) + cipher.final) rescue nil
    end

    def decrypt(str, pass: nil, salt: nil, type: nil)
      pass ||= @@salt
      type ||= DEFAULT_CIPHER_TYPE

      cipher = OpenSSL::Cipher.new type
      cipher.decrypt
      cipher.pkcs5_keyivgen pass, salt
      cipher.update(Base64.decode64(str)) + cipher.final rescue nil
    end
  end
end
