class Cms::Column::MultipleFilesUpload < Cms::Column::Base
  field :file_type, type: String, default: "image"
  field :header_input_setting, type: String, default: "show"
  validates :file_type, inclusion: { in: %w(image attachment) }
  validates :header_input_setting, inclusion: { in: %w(show hide) }
  permit_params :file_type, :header_input_setting

  def alignment_options
    %w(flow).map { |v| [ I18n.t("cms.options.alignment.#{v}"), v ] }
  end

  def form_check_enabled?
    true
  end

  def file_type_options
    %w(image attachment).map do |v|
      [ I18n.t("cms.options.multiple_files_upload_file_type.#{v}", default: v), v ]
    end
  end

  def header_input_setting_options
    %w(show hide).map do |v|
      [ I18n.t("cms.options.multiple_files_upload_header_input_setting.#{v}", default: v), v ]
    end
  end

  def header_enabled?
    header_input_setting != "hide"
  end

  class << self
    def default_attributes
      attrs = super
      attrs[:file_type] = "image"
      attrs[:header_input_setting] = "show"
      attrs
    end
  end
end
