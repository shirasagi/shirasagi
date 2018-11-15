class Cms::Column::FileUpload < Cms::Column::Base

  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''

  field :label_max_length, type: Integer
  field :label_place_holder, type: String

  field :file_type, type: String

  #validates :html_tag, inclusion: { in: %w(a+img a img), allow_blank: true }
  validates :file_type, inclusion: { in: %w(image video attachment banner), allow_blank: true }
  permit_params :html_tag, :html_additional_attr
  permit_params :label_max_length, :label_place_holder
  permit_params :file_type

  def html_tag_options
    %w(a+img a img).map do |v|
      [ I18n.t("cms.options.html_tag.#{v}", default: v), v ]
    end
  end

  def file_type_options
    %w(image video attachment banner).map do |v|
      [ I18n.t("cms.options.column_file_type.#{v}", default: v), v ]
    end
  end

  def form_options(type = nil)
    if type == :label
      options = {}
      options['maxlength'] = label_max_length if label_max_length.present?
      options['placeholder'] = label_place_holder if label_place_holder.present?
      options
    elsif type == :file_id
      {}
    elsif type == :image_text
      options = {}
      options['placeholder'] = I18n.t("cms.column_file_upload.image_text_place_holder")
      options
    elsif type == :video_description
      options = {}
      options['placeholder'] = I18n.t("cms.column_file_upload.video_description_place_holder")
      options
    elsif type == :attachment_text
      options = {}
      options['placeholder'] = I18n.t("cms.column_file_upload.attachment_text_place_holder")
      options['type'] = 'url'
      options
    elsif type == :banner_link
      options = {}
      options['placeholder'] = I18n.t("cms.column_file_upload.banner_link_place_holder")
      options
    elsif type == :banner_text
      options = {}
      options['placeholder'] = I18n.t("cms.column_file_upload.image_text_place_holder")
      options
    else
      super()
    end
  end
end
