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

  def import_csv(values)
    super

    case column.file_type
    when 'attachment'
      import_csv_attachment(values)
    when 'video'
      import_csv_video(values)
    when 'banner'
      import_csv_banner(values)
    else
      import_csv_image(values)
    end
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
      if old_file
        old_file.destroy
        self.file_id = nil
      end
    end

    return if file.blank?

    if @new_clone
      attributes = Hash[file.attributes]
      attributes.select!{ |k| file.fields.key?(k) }

      attributes["user_id"] = @cur_user.id if @cur_user
      attributes["_id"] = nil
      clone_file = SS::File.create_empty!(attributes, validate: false) do |new_file|
        ::FileUtils.copy(file.path, new_file.path)
      end
      clone_file.owner_item = _parent
      clone_file.save(validate: false)
      self.file = clone_file
    end

    attrs = {}

    if file.site_id != _parent.site_id
      attrs[:site_id] = _parent.site_id
    end
    if file.model != _parent.class.name
      attrs[:model] = _parent.class.name
    end
    if file.owner_item != _parent
      attrs[:owner_item] = _parent
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
    return nil unless File.exist?(file.path)

    path = "#{History::Trash.root}/#{file.path.sub(/.*\/(ss_files\/)/, '\\1')}"
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.cp(file.path, path)
    file.skip_history_trash = _parent.skip_history_trash if [ _parent, file ].all? { |obj| obj.respond_to?(:skip_history_trash) }
    file.destroy
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
    alt = file_label.presence.try { |l| ApplicationController.helpers.sanitize(l, tags: []) }
    alt ||= file.humanized_name
    if image_html_type == "thumb"
      ApplicationController.helpers.link_to(file.url) do
        ApplicationController.helpers.image_tag(file.thumb_url, alt: alt)
      end
    elsif image_html_type == "image"
      ApplicationController.helpers.image_tag(file.url, alt: alt)
    end
  end

  def to_default_html_attachment
    label = file_label.presence.try { |l| ApplicationController.helpers.sanitize(l) }
    label ||= file.name.sub(/\.[^\.]+$/, '')
    label = "#{label} (#{file.extname.upcase} #{file.size.to_s(:human_size)})"
    ApplicationController.helpers.link_to(label, file.url)
  end

  def to_default_html_video
    div_content = []
    div_content << ApplicationController.helpers.video_tag(file.url, controls: 'controls')
    escaped_text = ApplicationController.helpers.sanitize(ApplicationController.helpers.br(text, html_escape: false))
    div_content << ApplicationController.helpers.content_tag(:div, escaped_text)
    ApplicationController.helpers.content_tag(:div) do
      div_content.join.html_safe
    end
  end

  def to_default_html_banner
    alt = file_label.presence.try { |l| ApplicationController.helpers.sanitize(l, tags: []) }
    alt ||= file.humanized_name
    html = ApplicationController.helpers.image_tag(file.url, alt: alt)
    if link_url.present?
      html = ApplicationController.helpers.link_to(link_url) do
        html
      end
    end
    html
  end

  def import_csv_image(values)
    values.map do |name, value|
      case name
      when I18n.t("cms.column_file_upload.image.file_label")
        self.file_label = value
      when self.class.t(:image_html_type)
        self.image_html_type = value.present? ? I18n.t("cms.options.column_image_html_type").invert[value] : nil
      end
    end
  end

  def import_csv_attachment(values)
    values.map do |name, value|
      case name
      when I18n.t("cms.column_file_upload.attachment.file_label")
        self.file_label = value
      end
    end
  end

  def import_csv_video(values)
    values.map do |name, value|
      case name
      when I18n.t("cms.column_file_upload.video.text")
        self.text = value
      end
    end
  end

  def import_csv_banner(values)
    values.map do |name, value|
      case name
      when I18n.t("cms.column_file_upload.banner.link_url")
        self.link_url = value
      when I18n.t("cms.column_file_upload.banner.file_label")
        self.file_label = value
      end
    end
  end
end
