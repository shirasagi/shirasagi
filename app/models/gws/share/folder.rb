class Gws::Share::Folder
  include SS::Document
  include Gws::Model::Folder
  include Gws::Addon::Share::ResourceLimitation
  include Gws::Share::DescendantsFileInfo
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  #include SS::UserPermission
  #include Gws::Addon::File

  store_in collection: :gws_share_folders

  has_many :files, class_name: "Gws::Share::File", order: { created: -1 }, dependent: :destroy, autosave: false

  before_destroy :validate_files

  def quota_bytes
    return @quota_bytes if @quota_bytes

    if depth == 1
      @quota_bytes = share_max_folder_size
    else
      @quota_bytes = parents.where(depth: 1).first.try(:share_max_folder_size)
    end
    @quota_bytes ||= 0
  end

  def quota_label
    ret = total_file_size.to_s(:human_size)
    if quota_bytes > 0
      ret = "#{ret}/#{quota_bytes.to_s(:human_size)}"
    end
    ret
  end

  def quota_over?
    return false if quota_bytes <= 0

    total_file_size >= quota_bytes
  end

  def quota_percentage
    return 0 if quota_bytes <= 0

    percentage = (total_file_size.to_f / quota_bytes.to_f) * 100
    percentage > 100 ? 100 : percentage
  end

  private

  def validate_files
    if files.present?
      errors.add :base, :found_files
      return false
    end
    true
  end
end
