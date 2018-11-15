class Cms::Column::Value::FileUpload < Cms::Column::Value::Base
  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''
  belongs_to :file, class_name: 'SS::File'
  field :label, type: String

  permit_values :file_id, :label

  before_save :before_save_file
  after_destroy :delete_file

  liquidize do
    export :file
    export :label
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

    if file.model != 'cms/column'
      attrs[:model] = 'cms/column'
    end
    if file.state != _parent.state
      attrs[:state] = _parent.state
    end

    if attrs.present?
      file.set(attrs)
    end
  end

  def delete_file
    return if file.blank?

    self.file.destroy
    self.file_id = nil
  end

  # override Cms::Column::Value::Base#to_default_html
  def to_default_html
    return '' if file.blank?

    options = html_additional_attr_to_h
    case html_tag
    when 'a+img'
      outer_options = options.dup
      outer_options['class'] = [ options['class'] ].flatten.compact
      outer_options['class'] << file_icon
      ApplicationController.helpers.link_to(file.url, outer_options) do
        options['alt'] ||= file.name
        options['title'] ||= file.basename
        ApplicationController.helpers.image_tag(file.thumb_url, options)
      end
    when 'a'
      options['class'] = [ options['class'] ].flatten.compact
      options['class'] << file_icon
      ApplicationController.helpers.link_to(label.presence || file.humanized_name, file.url, options)
    when 'img'
      options['alt'] ||= file.name
      options['title'] ||= file.basename
      ApplicationController.helpers.image_tag(file.url, options)
    else
      ApplicationController.helpers.sanitize(file.humanized_name)
    end
  end
end
