class Cms::Column::Value::MultipleFilesUpload < Cms::Column::Value::Base
  field :file_ids, type: Array, default: []
  field :file_labels, type: Hash, default: {},
    metadata: { syntax_check: { files_alt_presence: ->{ image_type? || { message: :blank_file_link_text } } } }
  field :header, type: String

  permit_values :header, file_ids: [], file_labels: {}

  before_parent_save :before_save_files
  after_parent_destroy :destroy_files

  liquidize do
    export :files
    export :file_labels
    export :header
    export as: :items do
      files.map do |f|
        {
          "file" => f,
          "label" => file_labels[f.id.to_s],
          "file_label" => file_labels[f.id.to_s].to_s
        }
      end
    end
  end

  def file_type
    column.try(:file_type).presence || "image"
  end

  def image_type?
    file_type == "image"
  end

  def value
    files.map(&:name).join(", ")
  end

  def files
    return [] if file_ids.blank?

    records = SS::File.in(id: file_ids).to_a
    file_ids.filter_map { |fid| records.find { |f| f.id.to_s == fid.to_s } }
  end

  def all_file_ids
    file_ids.presence || []
  end

  def generate_public_files
    files.each(&:generate_public_file)
  end

  def remove_public_files
    owner = _parent
    files.each do |file|
      next if file.owner_item_id != owner.id
      next if file.owner_item_type != owner.class.name
      file.remove_public_file
    end
  end

  def history_summary
    h = []
    h << "#{t("header")}: #{header}" if header.present?
    h << "#{t("file_ids")}: #{files.map(&:name).join(", ")}" if file_ids.present?
    h.join(",")
  end

  # override Cms::Column::Value::Base#to_default_html
  def to_default_html
    return '' if file_ids.blank? && header.blank?

    helpers = ApplicationController.helpers
    parts = []
    parts << render_header(helpers) if header.present?
    parts << render_files(helpers) if file_ids.present?

    helpers.content_tag(:div, parts.join.html_safe, class: image_type? ? "images" : "attachments")
  end

  def search_values(values)
    return false unless values.instance_of?(Array)

    file_label_values = file_labels.present? ? file_labels.values : []
    file_names = files.map(&:name)
    file_urls = files.map(&:full_url)
    values.intersect?(file_label_values + file_names + file_urls + [header.to_s])
  end

  def file_label_for(file)
    file_labels[file.id.to_s] if file_labels.present?
  end

  class << self
    def form_example_layout
      h = []
      h << %({% if value.header.size > 0 %})
      h << %(  {% if column.file_type == 'image' %})
      h << %(    <div class="images-header">{{ value.header | newline_to_br }}</div>)
      h << %(  {% else %})
      h << %(    <div class="attachment-header">{{ value.header | newline_to_br }}</div>)
      h << %(  {% endif %})
      h << %({% endif %})
      h << %({% if value.items.size > 0 %})
      h << %(  {% if column.file_type == 'image' %})
      h << %(    <div class="column2">)
      h << %(      {% for item in value.items %})
      h << %(        <div class="column-item">)
      h << %(          <img src="{{ item.file.url }}" alt="{{ item.file_label }}">)
      h << %(        </div>)
      h << %(      {% endfor %})
      h << %(    </div>)
      h << %(  {% else %})
      h << %(    <ul class="attachment-list">)
      h << %(      {% for item in value.items %})
      h << %(        <li><a href="{{ item.file.url }}">{{ item.label | default: item.file.humanized_name }}</a></li>)
      h << %(      {% endfor %})
      h << %(    </ul>)
      h << %(  {% endif %})
      h << %({% endif %})
      h.join("\n")
    end
  end

  private

  def render_header(helpers)
    helpers.content_tag(:div, helpers.simple_format(header),
                        class: image_type? ? "images-header" : "attachment-header")
  end

  def render_files(helpers)
    if image_type?
      items = files.map do |file|
        alt = file_labels[file.id.to_s].to_s
        content = helpers.image_tag(file.url, alt: alt)
        helpers.content_tag(:div, content, class: "column-item")
      end
      helpers.content_tag(:div, items.join.html_safe, class: "column2")
    else
      items = files.map do |file|
        label = file_labels[file.id.to_s].presence.try { |l| helpers.sanitize(l) }
        label ||= file.name.sub(/\.[^.]+$/, '')
        label = "#{label} (#{file.extname.upcase} #{file.size.to_fs(:human_size)})"
        helpers.content_tag(:li, helpers.link_to(label, file.url))
      end
      helpers.content_tag(:ul, items.join.html_safe, class: "attachment-list")
    end
  end

  def validate_value
    return if column.blank?

    if column.required? && file_ids.blank?
      self.errors.add(:file_ids, :blank) unless skip_required?
    end

    if image_type?
      files.reject(&:image?).each do |non_image|
        self.errors.add(:file_ids, :only_image_file, filename: non_image.name)
      end
    end
  end

  def before_save_files
    removed_ids = (file_ids_was.presence || []).map(&:to_s) - (file_ids.presence || []).map(&:to_s)
    Cms::Reference::Files::Utils.delete_files(self, removed_ids) if removed_ids.present?

    return if file_ids.blank?

    new_file_ids = []
    files.each do |file|
      file = clone_file_if_necessary(file) || file
      update_file_owner_item(file)
      new_file_ids << file.id
    end
    self.file_ids = new_file_ids.map(&:to_s)
  end

  def clone_file_if_necessary(file)
    return nil unless file

    owner_item = SS::Model.container_of(self)
    return nil unless clone_needed?(file, owner_item)

    new_file = build_cloned_file(file, owner_item)
    new_file.update_variants if new_file.respond_to?(:update_variants)
    replace_file_id_and_label(file, new_file)
    new_file
  end

  def clone_needed?(file, owner_item)
    return false if SS::File.file_owned?(file, owner_item)
    return false if owner_item.try(:branch?) && SS::File.file_owned?(file, owner_item.master)
    Cms::Reference::Files::Utils.need_to_clone?(file, owner_item, owner_item.try(:in_branch))
  end

  def resolve_clone_context(owner_item)
    cur_site = owner_item.cur_site if owner_item.respond_to?(:cur_site)
    cur_site ||= owner_item.site if owner_item.respond_to?(:site)
    cur_site ||= SS.current_site
    cur_site = nil unless cur_site.is_a?(SS::Model::Site)
    cur_user = owner_item.cur_user if owner_item.respond_to?(:cur_user)
    cur_user ||= SS.current_user
    [cur_site, cur_user]
  end

  def build_cloned_file(file, owner_item)
    cur_site, cur_user = resolve_clone_context(owner_item)
    SS::File.clone_file(file, cur_site: cur_site, cur_user: cur_user, owner_item: owner_item) do |nf|
      nf.history_file_ids = file.history_file_ids if @merge_values
    end
  end

  def replace_file_id_and_label(old_file, new_file)
    idx = file_ids.index(old_file.id.to_s)
    file_ids[idx] = new_file.id.to_s if idx

    if file_labels.present? && file_labels.key?(old_file.id.to_s)
      file_labels[new_file.id.to_s] = file_labels.delete(old_file.id.to_s)
    end
  end

  def update_file_owner_item(file)
    owner_item = SS::Model.container_of(self)
    return if SS::File.file_owned?(file, owner_item)
    return if owner_item.respond_to?(:branch?) && owner_item.branch? && SS::File.file_owned?(file, owner_item.master)

    attrs = {}
    attrs[:site_id] = owner_item.site_id if file.site_id != owner_item.site_id
    attrs[:model] = owner_item.class.name if file.model != owner_item.class.name
    attrs[:owner_item] = owner_item if file.owner_item != owner_item
    attrs[:state] = owner_item.state if file.state != owner_item.state
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

  def destroy_files
    Cms::Reference::Files::Utils.delete_files(self, file_ids) if file_ids.present?
  end
end
