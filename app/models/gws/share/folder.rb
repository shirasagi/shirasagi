class Gws::Share::Folder
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  #include SS::UserPermission
  include Gws::Addon::File
  include Gws::Share::DescendantsFileInfo
  include Gws::Addon::History
  include SS::Fields::DependantNaming

  store_in collection: :gws_share_folders

  seqid :id
  field :name, type: String
  field :depth, type: Integer
  field :order, type: Integer, default: 0
  field :state, type: String, default: "closed"
  field :share_max_file_size, type: Integer, default: 0
  field :share_max_folder_size, type: Integer, default: 0
  attr_accessor :in_share_max_file_size_mb
  attr_accessor :in_share_max_folder_size_mb

  has_many :files, class_name: "Gws::Share::File", order: { created: -1 }, dependent: :destroy, autosave: false

  permit_params :name, :order, :share_max_file_size, :in_share_max_file_size_mb,
                :share_max_folder_size, :in_share_max_folder_size_mb

  before_validation :set_depth
  before_validation :set_share_max_file_size
  before_validation :set_share_max_folder_size

  validates :name, presence: true, length: {maximum: 80}
  validates :order, numericality: {less_than_or_equal_to: 999_999}
  validates :share_max_file_size,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1024**3, allow_blank: true }
  validates :share_max_folder_size,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1024**4, allow_blank: true }

  validate :validate_parent_name
  validate :validate_rename_children, :validate_rename_parent,
           :validate_children_move_to_other_parent, if: ->{ self.attributes["action"] == "update" }

  validate :validate_folder_name, if: ->{ self.attributes["action"] =~ /create|update/ }

  before_destroy :validate_children, :validate_files
  after_destroy :remove_zip

  default_scope ->{ order_by order: 1 }

  scope :sub_folder, ->(key, folder) {
    if key.start_with?('root_folder')
      where("$and" => [ {name: /^(?!.*\/).*$/} ] )
    else
      where("$and" => [ {name: /^#{folder}\/(?!.*\/).*$/} ] )
    end
  }

  class << self
    def search(params)
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    end

    def download_root_path
      "#{Rails.root}/private/files/gws_share_files/"
    end

    def zip_path(folder_id)
      self.download_root_path + folder_id.to_s.split(//).join("/") + "/_/#{folder_id}"
    end

    def create_download_directory(download_dir)
      FileUtils.mkdir_p(download_dir) unless Dir.exist?(download_dir)
    end

    def create_zip(zipfile, items, filename_duplicate_flag, folder_updated_time)
      if File.exist?(zipfile)
        return if folder_updated_time < File.stat(zipfile).mtime
        File.unlink(zipfile) if folder_updated_time > File.stat(zipfile).mtime
      end

      Zip::File.open(zipfile, Zip::File::CREATE) do |zip_file|
        items.each_with_index do |item, idx|
          def item.download_filename
            name =~ /\./ ? name : name.sub(/\..*/, '') + '.' + extname
          end
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

  def trailing_name
    @trailing_name ||= name.split("/")[depth-1..-1].join("/")
  end

  def parents
    @parents ||= begin
      paths = split_path(name.sub(/^\//, ''))
      paths.pop
      self.class.in(name: paths)
    end
  end

  def split_path(path)
    last = nil
    dirs = path.split('/').map { |n| last = last ? "#{last}/#{n}" : n }
  end

  def folders
    Gws::Share::Folder.where(site_id: site_id, name: /^#{name}\//)
  end

  def children(cond = {})
    folders.where cond.merge(depth: depth + 1)
  end

  private

  def set_depth
    self.depth = name.count('/') + 1 unless name.nil?
  end

  def set_share_max_file_size
    return if in_share_max_file_size_mb.blank?
    self.share_max_file_size = Integer(in_share_max_file_size_mb) * 1_024 * 1_024
  end

  def set_share_max_folder_size
    return if in_share_max_folder_size_mb.blank?
    self.share_max_folder_size = Integer(in_share_max_folder_size_mb) * 1_024 * 1_024
  end

  def remove_zip
    Fs.rm_rf self.class.zip_path(id) if File.exist?(self.class.zip_path(id))
  end

  def dependant_scope
    self.class.site(@cur_site || site)
  end

  def validate_parent_name
    return if name.blank?
    return if name.count('/') < 1

    if name.split('/')[name.count('/')].blank?
      errors.add :name, :blank
    else
      errors.add :base, :not_found_parent unless self.class.where(name: File.dirname(name)).exists?
    end
  end

  def validate_rename_children
    if self.attributes["before_folder_name"].include?("/") && !self.name.include?("/")
      errors.add :base, :not_move_to_parent
      return false
    end
    true
  end

  def validate_rename_parent
    if !self.attributes["before_folder_name"].include?("/") && self.attributes["before_folder_name"] != self.name
      errors.add :base, :not_rename_parent
      return false
    end
    true
  end

  def validate_children_move_to_other_parent
    if self.attributes["before_folder_name"].include?("/") &&
        self.attributes["before_folder_name"].split("/").first != self.name.split("/").first
      errors.add :base, :not_move_to_under_other_parent
      return false
    end
    true
  end

  def validate_children
    if name.present? && self.class.where(name: /^#{Regexp.escape(name)}\//).exists?
      errors.add :base, :found_children
      return false
    end
    true
  end

  def validate_files
    if files.present?
      errors.add :base, :found_files
      return false
    end
    true
  end

  def validate_folder_name
    if self.id == 0
      errors.add :base, :not_create_same_folder if self.class.site(site).where(name: self.name).first
    end

    if self.id != 0
      if self.class.site(site).where(name: self.name).present? && self.class.site(site).where(id: self.id).first.name != self.name
        errors.add :base, :not_move_to_same_name_folder
      end
    end
    true
  end
end
