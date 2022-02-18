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
      false
    end

    private

    def encrypt_file_fs_access_restriction_basic_auth_password
      return if in_file_fs_access_restriction_basic_auth_password.blank?
      self.file_fs_access_restriction_basic_auth_password = SS::Crypt.encrypt(in_file_fs_access_restriction_basic_auth_password)
    end
  end
end
