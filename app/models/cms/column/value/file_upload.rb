class Cms::Column::Value::FileUpload < Cms::Column::Value::Base
  attr_accessor :resource_url

  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''
  belongs_to :file, class_name: 'SS::File'
  field :file_name, type: String
  field :file_label, type: String
  field :text, type: String
  field :image_html_type, type: String
  field :link_url, type: String

  permit_values :file_id, :file_name, :file_label, :text, :image_html_type, :link_url

  before_parent_save :before_save_file
  after_parent_destroy :destroy_file

  liquidize do
    export :file
    export :file_name
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

  def history_summary
    h = []
    h << "#{t("file_name")}: #{file_name}" if file_name.present?
    h << "#{t("file_label")}: #{file_label}" if file_label.present?
    h << "#{t("image_html_type")}: #{I18n.t("cms.options.column_image_html_type.#{image_html_type}")}" if image_html_type.present?
    h << "#{t("text")}: #{text}" if text.present?
    h << "#{t("alignment")}: #{I18n.t("cms.options.alignment.#{alignment}")}"
    h.join(",")
  end

  def import_csv_cell(value)
    return if value == file.try(:full_url)
    return self.file_id = nil if value.blank?
    return self.file_id = nil unless validate_resouce_url(value)

    import_url_resource(value)
  end

  def import_url_resource(url)
    require 'open-uri'

    URI.parse(url).open do |f|
      attributes = {
        model: 'ss/temp_file',
        filename: ::File.basename(url),
        content_type: f.content_type,
        user_id: @cur_user.try(:id),
        site_id: @cur_site.try(:id),
      }
      download_file = SS::File.create_empty!(attributes) do |new_file|
        IO.copy_stream(f, new_file.path)
        new_file.sanitizer_copy_file
      end
      self.file_id = download_file.id
    end
  end

  def export_csv_cell
    file.try(:full_url)
  end

  def search_values(values)
    return false unless values.instance_of?(Array)
    (values & [file_label, file.try(:name), file.try(:full_url)]).present?
  end

  private

  def validate_resouce_url(value)
    /\Ahttps?:\/\//.match?(value) && Addressable::URI.parse(value) rescue false
  end

  def validate_value
    return if column.blank?

    if column.required? && file.blank?
      self.errors.add(:file_id, :blank)
    end

    if column.required? && column.file_type == 'banner' && link_url.blank?
      self.errors.add(:link_url, :blank)
    end

    self.file_name = file.name if file
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
      Cms::Reference::Files::Utils.delete_files(self, [ file_id_was ]) if file_id_was
    end

    return if file.blank?

    # 注意: カラム処理では以下の点が異なるので注意。
    #
    # - カラムは数が変更される可能性があるため、master から branch を作成する際も、master へ branch をマージする際も、
    #   delete & insert となるため常に @new_clone がセットされる。
    # - master から branch を作成する際は @merge_values はセットされないのに対し、
    #   master へ branch をマージする際は @merge_values がセットされる。
    # - ゴミ箱から復元する際は、@new_clone も @merge_values もセットされない。
    #
    # これらの全てのケースに対応する必要がある。
    clone_file_if_necessary
    update_file_owner_item
  end

  def clone_file_if_necessary
    return unless file

    owner_item = SS::Model.container_of(self)
    return if SS::File.file_owned?(file, owner_item)

    # 差し替えページの場合、ファイルの所有者が差し替え元なら、そのままとする
    return if owner_item.try(:branch?) && SS::File.file_owned?(file, owner_item.master)

    return unless Cms::Reference::Files::Utils.need_to_clone?(file, owner_item, owner_item.try(:in_branch))

    cur_user = owner_item.cur_user if owner_item.respond_to?(:cur_user)
    new_file = SS::File.clone_file(file, cur_user: cur_user, owner_item: owner_item) do |new_file|
      # history_files
      if @merge_values
        new_file.history_file_ids = file.history_file_ids
      end
    end

    # サムネイルを作成する
    new_file.update_variants if new_file.respond_to?(:update_variants)

    self.file = new_file
    self.file_id = new_file.id
  end

  def update_file_owner_item
    owner_item = SS::Model.container_of(self)
    return if SS::File.file_owned?(file, owner_item)

    # 差し替えページの場合、所有者を差し替え元のままとする
    return if owner_item.respond_to?(:branch?) && owner_item.branch? && SS::File.file_owned?(file, owner_item.master)

    attrs = {}

    if file.site_id != owner_item.site_id
      attrs[:site_id] = owner_item.site_id
    end
    if file.model != owner_item.class.name
      attrs[:model] = owner_item.class.name
    end
    if file.owner_item != owner_item
      attrs[:owner_item] = owner_item
    end
    if file.state != owner_item.state
      attrs[:state] = owner_item.state
    end

    return if attrs.blank?

    result = file.update(attrs)
    if result
      History::Log.build_file_log(file, site_id: owner_item.site_id, user_id: owner_item.cur_user.try(:id)).tap do |history|
        history.action = "update"
        history.behavior = "attachment"
        history.save
      end
    end
  end

  def destroy_file
    Cms::Reference::Files::Utils.delete_files(self, [ file_id ])
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
    label ||= file.name.sub(/\.[^.]+$/, '')
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

  class << self
    def form_example_layout
      h = []
      h << %({% if value.file %})
      h << %(  {% if value.image? %})
      h << %(    <a href="{{ value.file.url }}">)
      h << %(      <img src="{{ value.file.thumb_url }}")
      h << %(           alt="{{ value.image_text | default: value.file.humanized_name }}")
      h << %(           title="{{ value.file.basename }}"></a>)
      h << %(  {% else %})
      h << %(    <a href="{{ value.file.url }}">{{ value.attachment_text | default: value.file.humanized_name }}</a>)
      h << %(  {% endif %})
      h << %({% endif %})
      h.join("\n")
    end
  end
end
