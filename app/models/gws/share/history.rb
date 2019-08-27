class Gws::Share::History
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  seqid :id
  field :name, type: String
  field :mode, type: String, default: 'create'
  field :model, type: String
  field :model_name, type: String
  field :item_id, type: String
  field :updated_fields, type: Array
  field :updated_field_names, type: Array
  field :uploadfile_name, type: String
  field :uploadfile_filename, type: String
  field :uploadfile_srcname, type: String
  field :uploadfile_size, type: Integer
  field :uploadfile_content_type, type: String

  validates :name, presence: true
  validates :mode, presence: true
  validates :model, presence: true
  validates :item_id, presence: true

  before_save :set_string_data
  after_destroy :destroy_history_file

  default_scope -> {
    order_by created: -1
  }

  cattr_reader(:max_count) { SS.config.gws.share["max_history_count"] || 20 }

  def model_name
    self[:model_name] || I18n.t("mongoid.models.#{model}")
  end

  def mode_name
    I18n.t("gws.history.mode.#{mode}")
  end

  def item
    @item ||= model.camelize.constantize.where(id: item_id).first
  end

  def updated_field_names
    return self[:updated_field_names] if self[:updated_field_names]
    return [] if updated_fields.blank?

    updated_fields.map { |m| item ? item.t(m, default: '').presence : nil }.compact.uniq
  end

  def path
    return if item.blank?

    server_dir = ::File.dirname(item.path)
    ::File.join(server_dir, "#{item.id}_#{self.uploadfile_srcname}")
  end

  private

  def set_string_data
    self.model_name = model_name unless self[:model_name]
    self.updated_field_names = updated_field_names unless self[:updated_field_names]
  end

  def destroy_history_file
    return if path.blank?

    criteria = Gws::Share::History.where(model: model, item_id: item_id)
    criteria = criteria.where(uploadfile_srcname: uploadfile_srcname)
    criteria = criteria.ne(id: id)
    ref_count = criteria.count

    if ref_count == 0
      ::Fs.rm_rf(path)
    end
  end
end
