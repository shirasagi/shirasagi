class SS::MessageEncryptor
  class << self
    def secret
      @secret ||= Rails.application.secrets[:secret_key_base][0..31]
    end

    def basic_auth
      # TODO: SS.config.voice.download['basic_auth'] is deprecated
      @basic_auth ||= SS.config.cms.basic_auth || SS.config.voice.download['basic_auth']
    end

    def encryptor
      @encryptor ||= ::ActiveSupport::MessageEncryptor.new(secret, cipher: 'aes-256-cbc')
    end

    def http_basic_authentication
      @http_basic_authentication ||= decrypt(basic_auth) if basic_auth.present?
    end

    def encrypt(auth)
      case auth
      when Array
        auth.collect do |value|
          encryptor.encrypt_and_sign(value) rescue value
        end
      when String
        encryptor.encrypt_and_sign(auth) rescue auth
      end
    end

    def decrypt(auth)
      case auth
      when Array
        auth.collect do |value|
          encryptor.decrypt_and_verify(value) rescue value
        end
      when String
        encryptor.decrypt_and_verify(auth) rescue auth
      end
    end
  end
end
