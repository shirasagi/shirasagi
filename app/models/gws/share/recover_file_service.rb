class Gws::Share::RecoverFileService
  include ActiveModel::Model
  include ActiveModel::Attributes
  include SS::PermitParams
  include SS::HumanAttributeName

  attr_accessor :cur_site, :cur_user, :item

  attribute :name, :string
  attribute :folder_id, :integer

  permit_params :name, :folder_id

  validates :name, presence: true
  validates :folder_id, presence: true
  validate :validate_folder

  def folder
    id_to_folder_map[folder_id]
  end

  delegate :allowed?, :to_key, :to_param, to: :item

  def call
    return false if invalid?

    item.name = normalized_name
    item.folder_id = folder_id
    item.deleted = nil

    result = item.without_record_timestamps do
      item.save
    end

    if result
      update_folder_file_info
    else
      SS::Model.copy_errors(item, self)
    end

    result
  end

  private

  def target_folders
    @target_folders ||= begin
      target_folder_ids = [ folder_id.presence, item.folder_id ].compact
      Gws::Share::Folder.site(cur_site).in(id: target_folder_ids).to_a
    end
  end

  def id_to_folder_map
    @id_to_folder_map ||= target_folders.index_by(&:id)
  end

  def validate_folder
    return if folder_id.blank?
    return if id_to_folder_map[folder_id].present?

    errors.add :base, :not_found_parent
  end

  def normalized_name
    original_ext = File.extname(item.filename)
    ext = File.extname(name)
    return name if original_ext == ext

    "#{name}#{original_ext}"
  end

  def update_folder_file_info
    target_folders.each do |folder|
      folder.reload
      folder.update_folder_descendants_file_info
    end
  end
end
