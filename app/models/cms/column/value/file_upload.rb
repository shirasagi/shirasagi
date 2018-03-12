class Cms::Column::Value::FileUpload < Cms::Column::Value::Base
  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''
  belongs_to :file, class_name: 'SS::File'

  before_save :before_save_file
  after_destroy :delete_file

  def validate_value(record, attribute)
    return if column.blank?

    if column.required? && file.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if file.blank?
  end

  def update_value(new_value)
    self.name = new_value.name
    self.order = new_value.order
    self.html_tag = new_value.html_tag
    self.html_additional_attr = new_value.html_additional_attr
    self.file_id = new_value.file_id
  end

  def value
    file.try(:name)
  end

  def html_additional_attr_to_h
    return {} if html_additional_attr.blank?
    html_additional_attr.scan(/\S+?=".+?"/m).
      map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
      compact.to_h
  end

  def to_html
    return '' if file.blank?

    options = html_additional_attr_to_h
    case html_tag
    when 'a+img'
      outer_options = options.dup
      outer_options['class'] = [ options['class'] ].flatten.compact
      outer_options['class'] << file_icon
      ApplicationController.helpers.link_to(file.url, outer_options) do
        options['alt'] ||= file.name
        options['title'] ||= ::File.basename(file.filename)
        ApplicationController.helpers.image_tag(file.thumb_url, options)
      end
    when 'a'
      options['class'] = [ options['class'] ].flatten.compact
      options['class'] << file_icon
      ApplicationController.helpers.link_to(file.humanized_name, file.url, options)
    when 'img'
      options['alt'] ||= file.name
      options['title'] ||= ::File.basename(file.filename)
      ApplicationController.helpers.image_tag(file.url, options)
    else
      ApplicationController.helpers.sanitize(file.humanized_name)
    end
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
      attributes.select!{ |k| file.fields.keys.include?(k) }

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
end
