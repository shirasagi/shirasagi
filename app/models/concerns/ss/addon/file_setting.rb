module SS::Addon
  module FileSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file_resizing_width, :in_file_resizing_height, :in_file_fs_access_restriction_basic_auth_password

      field :file_resizing, type: Array, default: []
      field :multibyte_filename_state, type: String
      field :file_fs_access_restriction_state, type: String
      field :file_fs_access_restriction_allowed_ip_addresses, type: SS::Extensions::Lines
      field :file_fs_access_restriction_basic_auth_id, type: String
      field :file_fs_access_restriction_basic_auth_password, type: String
      field :file_fs_access_restriction_env_key, type: String
      field :file_fs_access_restriction_env_value, type: String

      permit_params :in_file_resizing_width, :in_file_resizing_height
      permit_params :multibyte_filename_state
      permit_params :file_fs_access_restriction_state, :file_fs_access_restriction_allowed_ip_addresses
      permit_params :file_fs_access_restriction_basic_auth_id, :in_file_fs_access_restriction_basic_auth_password
      permit_params :file_fs_access_restriction_env_key, :file_fs_access_restriction_env_value

      before_validation :set_file_resizing
      before_validation :encrypt_file_fs_access_restriction_basic_auth_password

      validates :multibyte_filename_state, inclusion: { in: %w(enabled disabled), allow_blank: true }
      validates :file_fs_access_restriction_state, inclusion: { in: %w(enabled disabled), allow_blank: true }
      validates :file_fs_access_restriction_allowed_ip_addresses, ip_address: true
    end

    def set_file_resizing
      self.file_resizing = []
      return if in_file_resizing_width.blank? || in_file_resizing_height.blank?

      width = in_file_resizing_width.to_i
      height = in_file_resizing_height.to_i

      width = 200 if width <= 200
      height = 200 if height <= 200

      self.file_resizing = [ width, height ]
    end

    def multibyte_filename_state_options
      %w(enabled disabled).map { |m| [ I18n.t("ss.options.multibyte_filename_state.#{m}"), m ] }
    end

    def file_fs_access_restriction_state_options
      %w(enabled disabled).map { |m| [ I18n.t("ss.options.state.#{m}"), m ] }
    end

    def multibyte_filename_disabled?
      multibyte_filename_state == 'disabled'
    end

    def multibyte_filename_enabled?
      !multibyte_filename_disabled?
    end

    def file_fs_access_restricted?
      file_fs_access_restriction_state == "enabled"
    end

    def file_fs_access_allowed?(request)
      return false if request.blank?

      if file_fs_access_restriction_allowed_ip_addresses.present?
        matcher = IPAddressMatcher.new(file_fs_access_restriction_allowed_ip_addresses)
        return true if matcher.match?(request)
      end
      if file_fs_access_restriction_basic_auth_id.present? && file_fs_access_restriction_basic_auth_password.present?
        password = SS::Crypto.decrypt(file_fs_access_restriction_basic_auth_password)
        matcher = BasicAuthMatcher.new(file_fs_access_restriction_basic_auth_id, password)
        return true if matcher.match?(request)
      end
      if file_fs_access_restriction_env_key.present?
        matcher = EnvMatcher.new(file_fs_access_restriction_env_key, file_fs_access_restriction_env_value.presence)
        return true if matcher.match?(request)
      end

      false
    end

    class IPAddressMatcher
      def initialize(ip_addresses)
        @ip_addresses = Array(ip_addresses).map do |addr|
          next if addr.blank?

          addr = addr.strip
          next if addr.blank? || addr.start_with?("#")

          IPAddr.new(addr)
        end.compact
      end

      def match?(request)
        remote_addr = request.env["HTTP_X_REAL_IP"].presence || request.remote_addr
        result = @ip_addresses.any? { |addr| addr.include?(remote_addr) }
        Rails.logger.warn { "remote address '#{remote_addr}' is not allowed" } unless result
        result
      end
    end

    class BasicAuthMatcher
      def initialize(id, password)
        @digest = Base64.strict_encode64("#{id}:#{password}")
      end

      def match?(request)
        authorization = request.authorization
        if authorization.blank?
          Rails.logger.warn { "authorization is not presented" }
          return false
        end

        type, digest = authorization.split(" ", 2)
        unless type.casecmp("basic").zero?
          Rails.logger.warn { "authorization type is not 'basic'" }
          return false
        end
        if digest != @digest
          Rails.logger.warn { "authorization credential is not matched" }
          return false
        end

        true
      end
    end

    class EnvMatcher
      def initialize(key, value = nil)
        @key = key
        @value = value
      end

      def match?(request)
        result = request.env.key?(@key)
        message = proc { "environment key '#{@key}' is not presented" }
        if result && @value
          result = request.env[@key] == @value
          message = proc { "environment value '#{request.env[@key]}' is not matched" }
        end

        Rails.logger.warn(&message) unless result
        result
      end
    end

    private

    def encrypt_file_fs_access_restriction_basic_auth_password
      return if in_file_fs_access_restriction_basic_auth_password.blank?
      self.file_fs_access_restriction_basic_auth_password = SS::Crypto.encrypt(in_file_fs_access_restriction_basic_auth_password)
    end
  end
end
