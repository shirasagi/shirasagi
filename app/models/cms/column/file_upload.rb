class Cms::Column::FileUpload < Cms::Column::Base

  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''

  validates :html_tag, inclusion: { in: %w(a+img a img), allow_blank: true }
  permit_params :html_tag, :html_additional_attr

  def html_tag_options
    %w(a+img a img).map do |v|
      [ I18n.t("cms.options.html_tag.#{v}", default: v), v ]
    end
  end

  def serialize_value(value)
    Cms::Column::Value::FileUpload.new(
      column_id: self.id, name: self.name, order: self.order, html_tag: self.html_tag,
      html_additional_attr: self.html_additional_attr, file_id: value
    )
  end
end
