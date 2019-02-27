class Cms::Column::Value::FileUpload < Cms::Column::Value::Base
  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''
  belongs_to :file, class_name: 'SS::File'
  field :file_label, type: String
  field :text, type: String
  field :image_html_type, type: String
  field :link_url, type: String

  permit_values :file_id, :file_label, :text, :image_html_type, :link_url

  before_save :before_save_file
  after_destroy :destroy_file

  liquidize do
    export :file
    export :file_label
    export :text
    export :image_html_type
    export :link_url
    export as: :file_type do
      column.try(:file_type)
    end
  end

  def value
    file.try(:name)
  end

  def all_file_ids
    [ file_id ]
  end

  def html_additional_attr_to_h
    return {} if html_additional_attr.blank?
    html_additional_attr.scan(/\S+?=".+?"/m).
      map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
      compact.to_h
  end

  def generate_public_files
    return if file.blank?
    file.generate_public_file
  end

  def remove_public_files
    return if file.blank?
    file.remove_public_file
  end

  private

  def validate_value
    return if column.blank?

    if column.required? && file.blank?
      self.errors.add(:file_id, :blank)
    end

    if column.required? && column.file_type == 'banner' && link_url.blank?
      self.errors.add(:link_url, :blank)
    end

    return if file.blank?
  end

  def copy_column_settings
    super

    return if column.blank?

    self.html_tag = column.html_tag
    self.html_additional_attr = column.html_additional_attr
  end

  def file_icon
    return '' if file.blank?
    "icon-#{::File.extname(file.filename).sub(/^\./, '')}"
  end

  def before_save_file
    if file_id_was.present? && file_id_was != file_id
      old_file = SS::File.find(file_id_was) rescue nil
      old_file.destroy if old_file
    end

    return if file.blank?

    if @new_clone
      attributes = Hash[file.attributes]
      attributes.select!{ |k| file.fields.key?(k) }

      clone_file = SS::File.new(attributes)
      clone_file.id = nil
      clone_file.in_file = file.uploaded_file
      clone_file.user_id = @cur_user.id if @cur_user

      clone_file.save(validate: false)

      self.file = clone_file
    end

    attrs = {}

    if file.site_id != _parent.site_id
      attrs[:site_id] = _parent.site_id
    end
    if file.model != 'cms/column'
      attrs[:model] = 'cms/column'
    end
    if file.state != _parent.state
      attrs[:state] = _parent.state
    end

    if attrs.present?
      file.update(attrs)
    end
  end

  def destroy_file
    return if file.blank?

    self.file.destroy
    self.file_id = nil
  end

  # override Cms::Column::Value::Base#to_default_html
  def to_default_html
    return '' if file.blank?

    case column.file_type
    when 'attachment'
      to_default_html_attachment
    when 'video'
      to_default_html_video
    when 'banner'
      to_default_html_banner
    else # 'image'
      to_default_html_image
    end
  end

  def to_default_html_image
    if image_html_type == "thumb"
      ApplicationController.helpers.link_to(file.url) do
        ApplicationController.helpers.image_tag(file.thumb_url, alt: file_label.presence || file.humanized_name)
      end
    elsif image_html_type == "image"
      ApplicationController.helpers.image_tag(file.url, alt: file_label.presence || file.humanized_name)
    end
  end

  def to_default_html_attachment
    label = "#{file_label.presence || file.name.sub(/\.[^\.]+$/, '')} (#{file.extname.upcase} #{file.size.to_s(:human_size)})"
    ApplicationController.helpers.link_to(label, file.url)
  end

  def to_default_html_video
    div_content = []
    div_content << ApplicationController.helpers.video_tag(file.url, controls: 'controls')
    div_content << ApplicationController.helpers.content_tag(:div, ApplicationController.helpers.br(text))
    ApplicationController.helpers.content_tag(:div) do
      div_content.join.html_safe
    end
  end

  def to_default_html_banner
    html = ApplicationController.helpers.image_tag(file.url, alt: file_label.presence || file.humanized_name)
    if link_url.present?
      html = ApplicationController.helpers.link_to(link_url) do
        html
      end
    end
    html
  end
end
