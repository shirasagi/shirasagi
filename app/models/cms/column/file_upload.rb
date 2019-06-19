class Cms::Column::FileUpload < Cms::Column::Base
  # backward compatibility fields
  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''
  field :label_max_length, type: Integer
  field :label_place_holder, type: String

  # regal fields
  field :file_type, type: String
  validates :file_type, inclusion: { in: %w(image video attachment banner), allow_blank: true }
  permit_params :file_type

  def alignment_options
    if file_type.blank? || file_type == "image"
      return %w(flow left center right).map { |v| [ I18n.t("cms.options.alignment.#{v}"), v ] }
    end

    super
  end

  def file_type_options
    %w(image video attachment banner).map do |v|
      [ I18n.t("cms.options.column_file_type.#{v}", default: v), v ]
    end
  end

  def image_html_type_options
    %w(image thumb).map do |v|
      [ I18n.t("cms.options.column_image_html_type.#{v}", default: v), v ]
    end
  end

  def syntax_check_enabled?
    true
  end

  def link_check_enabled?
    true
  end

  def form_check_enabled?
    super || (label_max_length.present? && label_max_length > 0) || (file_type == 'banner')
  end
end
