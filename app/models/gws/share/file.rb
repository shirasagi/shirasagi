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
  #validates :folder_id, presence: true
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
      where({}).order_by(created: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('updated_')
      where({}).order_by(updated: key.end_with?('_asc') ? 1 : -1)
    else
      where({})
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
        criteria = criteria.in(folder_id: params[:folder])
      end

      criteria
    end

    def download_root_path
      "#{Rails.root}/private/files/gws_share_files/"
    end

    def zip_path(user_id, tmp_dir_name)
      self.download_root_path + user_id.to_s + "_" + tmp_dir_name + "/" + user_id.to_s
    end

    def create_download_directory(user_id, root_temp_dir, temp_dir)
      Dir.glob(root_temp_dir + "/" + user_id.to_s + "_*").each do |tmp|
        FileUtils.rm_rf(File.dirname(tmp)) if File.exists?(File.dirname(tmp))
      end

      FileUtils.mkdir_p(File.dirname(temp_dir)) unless FileTest.exist?(File.dirname(temp_dir))
    end

    def create_zip(zipfile, items, filename_duplicate_flag)
      Zip::File.open(zipfile, Zip::File::CREATE) do |zip_file|
        items.each do |item|
          if File.exist?(item.path)
            if filename_duplicate_flag == 0
              zip_file.add(NKF::nkf('-sx --cp932', item.download_filename), item.path)
            elsif filename_duplicate_flag == 1
              zip_file.add(NKF::nkf('-sx --cp932', item._id.to_s + "_" + item.download_filename), item.path)
            end
          end
        end
      end
    end
  end

  def remove_public_file
    # TODO: fix SS::Model::File
  end

  def folder_options
    Gws::Share::Folder.site(@cur_site).allow(:read, @cur_user, site: @cur_site).pluck(:name, :id)
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
    %w(updated_desc updated_asc created_desc created_asc).map { |k| [I18n.t("ss.options.sort.#{k}"), k] }
  end

  private

  def validate_size
    return if cur_site.nil?

    @folder_max_size = 0
    if folder
      folder.files.each do |file|
        @folder_max_size += (file.size || 0)
      end
      @file_max_size = folder.files.max_by { |file| file.size || 0 }.size || 0
      folder_share_max_folder_size = folder.share_max_folder_size
      folder_share_max_file_size = folder.share_max_file_size
    else
      @file_max_size = 0
      folder_share_max_folder_size = 0
      folder_share_max_file_size = 0
    end

    if @cur_site
      if (folder_limit = (folder_share_max_folder_size || 0)) > 0
        size = @folder_max_size
        if size > folder_limit
          errors.add(:base,
                     :file_size_exceeds_folder_limit,
                     size: number_to_human_size(size),
                     limit: number_to_human_size(folder_limit))
        end
      end
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
    setting_validate_size if @cur_site.share_max_file_size > folder_share_max_file_size ||
        @cur_site.share_files_capacity > folder_share_max_folder_size
  end

  def setting_validate_size
    limit = @cur_site.share_max_file_size || 0
    capacity = @cur_site.share_files_capacity || 0
    return if limit <= 0 && capacity <= 0

    if in_file.present?
      size = in_file.size
    elsif in_files.present?
      size = in_files.map(&:size).max || 0
    end

    if size > limit
      errors.add(:base, :file_size_exceeds_limit, size: number_to_human_size(size), limit: number_to_human_size(limit))
    end

    total = Gws::Share::File.site(@cur_site).not_in(id: id).map(&:size).inject(:+) || 0
    total += in_file.size if in_file.present?

    if total > capacity
      errors.add(:base, :file_size_exceeds_capacity, size: number_to_human_size(total), limit: number_to_human_size(capacity))
    end
  end

end
