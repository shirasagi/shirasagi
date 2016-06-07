module Member::ExpirableSecureId
  extend ActiveSupport::Concern

  # TODO: 有効な時間は、設定画面から変更できるほうがいい？
  SECURE_ID_TIME_LIMIT = (24 * 3600).freeze

  def secure_id
    salt = Rails.application.secrets.secret_key_base
    cipher = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    cipher.encrypt
    cipher.pkcs5_keyivgen(salt, nil)
    secret = cipher.update("#{id},#{Time.zone.now.to_i}") + cipher.final
    secret.unpack("H*")[0]
  end

  module ClassMethods
    def decode_secure_id(secure_id)
      return nil if secure_id.blank?

      salt = Rails.application.secrets.secret_key_base
      cipher = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
      begin
        cipher.decrypt
        cipher.pkcs5_keyivgen(salt, nil)
        secure = cipher.update([secure_id].pack("H*")) + cipher.final
      rescue OpenSSL::Cipher::CipherError => e
        return nil
      end
      id, timestamp = secure.split(',')
      id = id.to_i
      timestamp = timestamp.to_i
      # secure_id は 24 時間だけ有効
      elapsed = Time.zone.now.to_i - timestamp
      return nil if elapsed > SECURE_ID_TIME_LIMIT

      id
    end

    def find_by_secure_id(secure_id)
      id = decode_secure_id(secure_id)
      raise Mongoid::Errors::DocumentNotFound.new(self.class, secure_id: secure_id) if id.nil?
      self.find(id)
    end
  end
end
