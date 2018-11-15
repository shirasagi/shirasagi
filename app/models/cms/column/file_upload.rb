class Cms::Column::FileUpload < Cms::Column::Base

  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''

  field :label_max_length, type: Integer
  field :label_place_holder, type: String

  validates :html_tag, inclusion: { in: %w(a+img a img), allow_blank: true }
  permit_params :html_tag, :html_additional_attr
  permit_params :label_max_length, :label_place_holder

  def html_tag_options
    %w(a+img a img).map do |v|
      [ I18n.t("cms.options.html_tag.#{v}", default: v), v ]
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
    else
      super()
    end
  end
end
