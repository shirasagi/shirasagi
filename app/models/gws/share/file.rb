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

  class << self
    def search(params)
      criteria = super
      return criteria if params.blank?

      if params[:category].present?
        category_ids = Gws::Share::Category.site(params[:site]).and_name_prefix(params[:category]).pluck(:id)
        criteria = criteria.in(category_ids: category_ids)
      end

      if params[:folder].present?
        criteria = criteria.in(folder_id: params[:folder])
      end

      criteria
    end
  end

  def remove_public_file
    # TODO: fix SS::Model::File
  end

  def folder_options
    Gws::Share::Folder.site(@cur_site).allow(:read, @cur_user, site: @cur_site).map do |item|
      [item.name, item.id]
    end
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


  private

  def validate_size
    return if cur_site.nil?
    if @cur_site && folder
      if (limit = (folder.share_max_file_size || 0)) > 0
        size = folder.files.compact.map(&:size).max || 0
        if size > limit
          errors.add(
              :base,
              :file_size_exceeds_folder_limit,
              size: number_to_human_size(size),
              limit: number_to_human_size(limit))
        end
      end
    else
      @cur_site = Gws::Group.find(site_id) unless @cur_site
    end
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
end
