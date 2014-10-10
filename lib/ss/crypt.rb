require 'digest/md5'
require 'openssl'
require 'base64'
module SS::Crypt
  @@salt = Rails.application.secrets.secret_key_base || "ss-salt"

  class << self
    public
      def crypt(str, opts = {})
        salt = opts[:salt] || @@salt
        Digest::MD5.hexdigest(Digest::MD5.digest(str) + salt)
      end

      def encrypt(str, opts = {})
        opts = { pass: @@salt, salt: nil, type: "AES-256-CBC" }.merge(opts)
        cipher = OpenSSL::Cipher::Cipher.new opts[:type]
        cipher.encrypt
        cipher.pkcs5_keyivgen opts[:pass], opts[:salt]
        Base64.encode64(cipher.update(str) + cipher.final) rescue nil
      end

      def decrypt(str, opts = {})
        opts = { pass: @@salt, salt: nil, type: "AES-256-CBC" }.merge(opts)
        cipher = OpenSSL::Cipher::Cipher.new opts[:type]
        cipher.decrypt
        cipher.pkcs5_keyivgen opts[:pass], opts[:salt]
        cipher.update(Base64.decode64(str)) + cipher.final rescue nil
      end
  end
end
