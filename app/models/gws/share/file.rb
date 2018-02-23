class Gws::Share::File
  include Gws::Model::File
  include Gws::Referenceable
  include Gws::Reference::Site
  include Gws::Addon::EditLock
  include Gws::Addon::Share::Category
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::Share::History

  field :folder_id, type: Integer
  field :deleted, type: DateTime
  permit_params :folder_id, :deleted

  belongs_to :folder, class_name: "Gws::Share::Folder"

  #validates :category_ids, presence: true
  validates :folder_id, presence: true
  validate :validate_size, if: ->{ in_file.present? }
  validates :deleted, datetime: true

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::ShareFileJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::ShareFileJob.callback

  default_scope ->{ where(model: "share/file") }

  scope :active, ->(date = Time.zone.now) {
    where('$and' => [
        { '$or' => [{ deleted: nil }, { :deleted.gt => date }] }
    ])
  }

  scope :deleted, -> {
    where(:deleted.exists => true)
  }

  scope :custom_order, ->(key) {
    if key.start_with?('created_')
      all.reorder(created: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('updated_')
      all.reorder(updated: key.end_with?('_asc') ? 1 : -1)
    elsif key == 'filename'
      all.reorder(name: 1)
    else
      all
    end
  }

  class << self
    def search(params)
      criteria = super
      return criteria if params.blank?

      if params[:category].present?
        category_ids = Gws::Share::Category.site(params[:site]).and_name_prefix(params[:category]).pluck(:id)
        criteria = criteria.in(category_ids: category_ids)
      end

      if params[:folder].present?
        criteria = criteria.where(folder_id: params[:folder])
      end

      criteria
    end
  end

  def remove_public_file
    # TODO: fix SS::Model::File
  end

  def folder_options
    library = Gws::Share::Folder.find(folder_id).name.split('/')[0].to_s
    Gws::Share::Folder.site(@cur_site)
      .allow(:read, @cur_user, site: @cur_site)
      .where(name: /^#{library}$|^#{library}\// )
      .pluck(:name, :id)
  end

  def active?
    return true unless deleted.present? && deleted < Time.zone.now
    false
  end

  def active
    update_attributes(deleted: nil)
  end

  def disable
    update_attributes(deleted: Time.zone.now) if deleted.blank? || deleted > Time.zone.now
  end

  def sort_options
    %w(updated_desc updated_asc filename created_desc created_asc).map { |k| [I18n.t("ss.options.sort.#{k}"), k] }
  end

  private

  def validate_size
    return if cur_site.nil?

    @folder_max_size = 0

    parent_folder_name = folder.name.split("/").first
    parent_folder = Gws::Share::Folder.where(name: parent_folder_name).site(@cur_site).first
    child_folders = Gws::Share::Folder.where(name: /^#{parent_folder_name}\/.*/).site(@cur_site)

    child_folders.each do |child_folder|
      child_folder.files.each do |file|
        @folder_max_size += (file.size || 0)
      end
    end if child_folders.present?

    parent_folder.files.each do |file|
      @folder_max_size += (file.size || 0)
    end if parent_folder.present?

    @file_max_size = folder.files.max_by { |file| file.size || 0 }.size || 0

    if folder.name.include?("/")
      folder_share_max_folder_size = Gws::Share::Folder.where(name: folder.name.split("/").first)
                                         .site(@cur_site).first.share_max_folder_size
      folder_share_max_file_size = Gws::Share::Folder.where(name: folder.name.split("/").first)
                                       .site(@cur_site).first.share_max_file_size
    else
      folder_share_max_folder_size = folder.share_max_folder_size
      folder_share_max_file_size = folder.share_max_file_size
    end

    if @cur_site
      validate_folder_limit(folder_share_max_folder_size)
      validate_file_limit(folder_share_max_file_size)
    end
    setting_validate_size if @cur_site.share_max_file_size > folder_share_max_file_size
    setting_validate_capacity if folder_share_max_folder_size.to_i == 0
  end

  def validate_folder_limit(folder_share_max_folder_size)
    if (folder_limit = (folder_share_max_folder_size || 0)) > 0
      size = @folder_max_size
      if size > folder_limit
        errors.add(:base,
                   :file_size_exceeds_folder_limit,
                   size: number_to_human_size(size),
                   limit: number_to_human_size(folder_limit))
      end
    end
  end

  def validate_file_limit(folder_share_max_file_size)
    if (limit = (folder_share_max_file_size || 0)) > 0
      size = @file_max_size
      if size > limit
        errors.add(:base,
                   :file_size_exceeds_limit,
                   size: number_to_human_size(size),
                   limit: number_to_human_size(limit))
      end
    end
  end

  def setting_validate_size
    limit = @cur_site.share_max_file_size || 0
    return if limit <= 0

    if in_file.present?
      size = in_file.size
    elsif in_files.present?
      size = in_files.map(&:size).max || 0
    else
      return
    end

    if size > limit
      errors.add(:base, :file_size_exceeds_limit, size: number_to_human_size(size), limit: number_to_human_size(limit))
    end
  end

  def setting_validate_capacity
    capacity = @cur_site.share_files_capacity || 0
    return if capacity <= 0

    total = Gws::Share::File.site(@cur_site).not_in(id: id).map(&:size).inject(:+) || 0
    total += in_file.size if in_file.present?

    if total > capacity
      errors.add(:base, :file_size_exceeds_capacity, size: number_to_human_size(total), limit: number_to_human_size(capacity))
    end
  end
end
