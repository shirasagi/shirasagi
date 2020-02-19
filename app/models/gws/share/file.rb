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
  field :memo, type: String
  permit_params :folder_id, :deleted, :memo

  belongs_to :folder, class_name: "Gws::Share::Folder"

  #validates :category_ids, presence: true
  validates :folder_id, presence: true
  validate :validate_size
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
    elsif key.start_with?('filename_')
      all.reorder(name: key.end_with?('_asc') ? 1 : -1)
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
    library = ::Regexp.escape(library)
    Gws::Share::Folder.site(@cur_site)
      .allow(:read, @cur_user, site: @cur_site)
      .where(name: /\A#{library}\z|\A#{library}\// )
      .pluck(:name, :id)
  end

  def active?
    deleted.blank? || deleted > Time.zone.now
  end

  def active
    update(deleted: nil)
  end

  def disable
    update(deleted: Time.zone.now) if deleted.blank? || deleted > Time.zone.now
  end

  def sort_options
    %w(filename_asc filename_desc updated_desc updated_asc created_desc created_asc).map do |k|
      [I18n.t("ss.options.sort.#{k}"), k]
    end
  end

  def new_flag?
    created > Time.zone.now - site.share_new_days.day
  end

  private

  def validate_size
    return if in_file.blank? && !Array(validation_context).include?(:change_model)

    effective_site = @cur_site || self.site
    return if effective_site.blank?

    root_folder = begin
      if folder.name.include?("/")
        root_folder_name = folder.name.split("/").first
        Gws::Share::Folder.site(effective_site).where(name: root_folder_name).first
      else
        folder
      end
    end
    return if root_folder.blank?

    context = { site: effective_site, root_folder: root_folder, size: in_file ? in_file.size : self.size }

    # validate with folder setting
    validate_size_with_folder_share_max_file_size(context)
    validate_size_with_folder_share_max_folder_size(context)

    # validate with site setting
    validate_size_with_site_share_max_file_size(context)
    validate_size_with_site_share_files_capacity(context)
  end

  def validate_size_with_folder_share_max_file_size(context)
    limit = context[:root_folder].share_max_file_size
    return if limit <= 0

    effective_size = context[:size]
    if effective_size > limit
      errors.add(:base, :file_size_exceeds_limit, size: number_to_human_size(effective_size), limit: number_to_human_size(limit))
    end
  end

  def validate_size_with_folder_share_max_folder_size(context)
    limit = context[:root_folder].share_max_folder_size
    return if limit <= 0

    total = context[:root_folder].descendants_total_file_size || 0
    total += context[:size]

    return if total <= limit

    errors.add(:base, :file_size_exceeds_folder_limit, size: number_to_human_size(total), limit: number_to_human_size(limit))
  end

  def validate_size_with_site_share_max_file_size(context)
    limit = context[:site].share_max_file_size || 0
    return if limit <= 0

    effective_size = context[:size]
    return if effective_size <= limit

    errors.add(:base, :file_size_exceeds_limit, size: number_to_human_size(effective_size), limit: number_to_human_size(limit))
  end

  def validate_size_with_site_share_files_capacity(context)
    limit = context[:site].share_files_capacity || 0
    return if limit <= 0

    # total = Gws::Share::File.site(context[:site]).not_in(id: id).pluck(:size).sum || 0
    total = Gws::Share::Folder.site(context[:site]).where(depth: 1).pluck(:descendants_total_file_size).sum || 0
    total += context[:size]

    return if total <= limit

    errors.add(:base, :file_size_exceeds_capacity, size: number_to_human_size(total), limit: number_to_human_size(limit))
  end
end
