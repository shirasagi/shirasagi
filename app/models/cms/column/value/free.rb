class Cms::Column::Value::Free < Cms::Column::Value::Base
  field :value, type: String
  field :contains_urls, type: Array, default: []

  embeds_ids :files, class_name: "SS::File"

  permit_values :value, file_ids: []

  before_save :before_save_files
  after_destroy :destroy_files
  after_save :put_contains_urls_logs
  before_validation :set_contains_urls

  liquidize do
    export :value
    export :files
  end

  def all_file_ids
    file_ids
  end

  private

  def validate_value
    return if column.blank?

    if column.required? && value.blank?
      self.errors.add(:value, :blank)
    end

    return if value.blank?

    if column.max_length.present? && column.max_length > 0
      if value.length > column.max_length
        self.errors.add(:value, :too_long, count: column.max_length)
      end
    end
  end

  def to_default_html
    value
  end

  def before_save_files
    if @new_clone
      cloned_file_ids = []
      file_ids.each_slice(20) do |ids|
        SS::File.in(id: ids).to_a.each do |source_file|
          attributes = Hash[source_file.attributes]
          attributes.select!{ |k| source_file.fields.key?(k) }

          attributes["user_id"] = @cur_user.id if @cur_user
          attributes["_id"] = nil
          attributes["model"] = _parent.class.name
          attributes["state"] = _parent.state
          clone_file = SS::File.create_empty!(attributes, validate: false) do |new_file|
            ::FileUtils.copy(source_file.path, new_file.path)
          end
          clone_file.owner_item = _parent
          clone_file.save(validate: false)
          result = clone_file

          next unless result

          cloned_file_ids << clone_file.id

          cloned_value = self.value
          cloned_value.gsub!("=\"#{source_file.url}\"", "=\"#{clone_file.url}\"")
          cloned_value.gsub!("=\"#{source_file.thumb_url}\"", "=\"#{clone_file.thumb_url}\"")
          self.value = cloned_value
        end
      end

      self.file_ids = cloned_file_ids
    else
      del_ids = file_ids_was.to_a - file_ids
      del_ids.each_slice(20) do |ids|
        SS::File.in(id: ids).destroy_all
      end

      add_ids = _parent.state_changed? ? file_ids : file_ids - file_ids_was.to_a
      add_ids.each_slice(20) do |ids|
        SS::File.in(id: ids).to_a.each do |file|
          file.update(site_id: _parent.site_id, model: _parent.class.name, owner_item: _parent, state: _parent.state)
        end
      end

      self.file_ids = file_ids + add_ids - del_ids
    end
  end

  def destroy_files
    if !_parent.respond_to?(:skip_history_trash)
      files.destroy_all
      return
    end

    file_ids.each_slice(20) do |ids|
      SS::File.in(id: ids).to_a.map(&:becomes_with_model).each do |file|
        file.skip_history_trash = _parent.skip_history_trash if file.respond_to?(:skip_history_trash)
        file.destroy
      end
    end
  end

  def create_history_log(file)
    site_id = nil
    user_id = nil
    site_id = self._parent.cur_site.id if self._parent.cur_site.present?
    user_id = self._parent.cur_user.id if self._parent.cur_user.present?
    History::Log.new(
      site_id: site_id,
      user_id: user_id,
      session_id: Rails.application.current_session_id,
      request_id: Rails.application.current_request_id,
      controller: self.model_name.i18n_key,
      url: file.try(:url),
      page_url: Rails.application.current_path_info,
      ref_coll: file.try(:collection_name)
    )
  end

  def put_contains_urls_logs
    add_contains_urls = self._parent.value_contains_urls - self._parent.value_contains_urls_was.to_a
    add_contains_urls.each do |file|
      item = create_history_log(file)
      item.url = file
      item.action = "update"
      item.behavior = "paste"
      item.ref_coll = ":ss_files"
      item.save
    end

    del_contains_urls = self._parent.value_contains_urls_was.to_a - self._parent.value_contains_urls
    del_contains_urls.each do |file|
      item = create_history_log(file)
      item.url = file
      item.action = "destroy"
      item.behavior = "paste"
      item.ref_coll = ":ss_files"
      item.save
    end
  end

  def set_contains_urls
    if value.blank?
      self.contains_urls = [] if self.contains_urls.present?
    else
      self.contains_urls = value.scan(/(?:href|src)="(.*?)"/).flatten.uniq
    end
    self._parent.value_contains_urls = self.contains_urls
  end
end
