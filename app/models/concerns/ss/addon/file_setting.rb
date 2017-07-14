module SS::Addon
  module FileSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file_resizing_width, :in_file_resizing_height

      field :file_resizing, type: Array, default: []
      field :multibyte_filename, type: String
      validates :multibyte_filename, inclusion: { in: %w(enabled disabled), allow_blank: true }
      permit_params :in_file_resizing_width, :in_file_resizing_height
      permit_params :multibyte_filename

      before_validation :set_file_resizing
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

    def multibyte_filename_options
      %w(enabled disabled).map { |m| [ I18n.t("ss.options.state.#{m}"), m ] }.to_a
    end

    def multibyte_filename_enabled?
      multibyte_filename != 'disabled'
    end
  end
end
