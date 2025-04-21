class Gws::Column::Value::FileUpload < Gws::Column::Value::Base
  embeds_ids :files, class_name: 'SS::File'

  attr_accessor :in_clone_file

  before_save :before_save_files
  before_save :before_save_clone, if: ->{ in_clone_file }
  after_destroy :delete_files

  def validate_value(record, attribute)
    return if column.blank?

    if column.required? && files.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if files.blank?

    if files.count > column.upload_file_count
      message = I18n.t(
        'errors.messages.file_count',
        size: ApplicationController.helpers.number_to_human(files.count),
        limit: ApplicationController.helpers.number_to_human(column.upload_file_count)
      )
      record.errors.add(:base, "#{name}#{message}")
    end

    # files.each do |file|
    #   if file.size > column.max_upload_file_size
    #     message = I18n.t(
    #       'errors.messages.too_large_file',
    #       filename: file.humanize_name,
    #       size: ApplicationController.helpers.number_to_human_size(file.size),
    #       limit: ApplicationController.helpers.number_to_human_size(column.max_upload_file_size)
    #     )
    #     record.errors.add(:base, "#{name}#{message}")
    #   end
    # end
  end

  def update_value(new_value)
    self.name = new_value.name
    self.order = new_value.order
    self.file_ids = new_value.file_ids
    self.text_index = new_value.value
  end

  def update_file_owner(parent)
    files.each do |file|
      file.owner_item = parent
      file.save
    end
  end

  def value
    files.pluck(:name).join(', ')
  end

  private

  def before_save_files
    if file_ids_was.present?
      removed_file_ids = normalized_file_ids(file_ids_was) - normalized_file_ids(file_ids)
      removed_file_ids.each do |file_id|
        removed_file = SS::File.find(file_id) rescue nil
        removed_file.destroy if removed_file
      end
    end

    owner_item = SS::Model.container_of(self)
    model_name = _parent.class.name
    cur_user = _parent.try(:cur_user) || _parent.try(:user)
    cur_user ||= SS.current_user
    new_file_ids = []
    SS::File.each_file(file_ids) do |file|
      if file.blank? || file.model == model_name
        new_file_ids << file.id
        next
      end

      if Cms::Reference::Files::Utils.need_to_clone?(file, owner_item, nil)
        file = SS::File.clone_file(file, cur_user: cur_user, owner_item: owner_item)
      end

      file.model = model_name
      file.owner_item = owner_item
      file.without_record_timestamps { file.save! }
      new_file_ids << file.id
    end

    self.file_ids = new_file_ids
  end

  def before_save_clone
    ids = {}
    owner_item = SS::Model.container_of(self)
    files.each do |f|
      attributes = Hash[f.attributes]
      attributes.slice!(*f.fields.keys)

      file = SS::File.new(attributes)
      file.id = nil
      file.in_file = f.uploaded_file
      file.user_id = @cur_user.id if @cur_user
      file.owner_item = owner_item

      file.save validate: false
      ids[f.id] = file.id
    end
    self.file_ids = ids.values
  end

  def delete_files
    return if files.blank?

    self.files.destroy_all
    self.file_ids = nil
  end

  def normalized_file_ids(ids)
    return [] if ids.blank?
    ids.select(&:present?).map(&:to_i)
  end
end
