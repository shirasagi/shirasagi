class Cms::Column::MultipleFilesUpload < Cms::Column::Base
  field :file_type, type: String, default: "image"
  validates :file_type, inclusion: { in: %w(image attachment) }
  permit_params :file_type

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

  class << self
    def default_attributes
      attrs = super
      attrs[:file_type] = "image"
      attrs
    end
  end
end
