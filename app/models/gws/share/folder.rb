class Gws::Share::Folder
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  #include SS::UserPermission
  #include Gws::Addon::File
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

  before_validation :set_depth, if: ->{ name.present? }
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

  default_scope ->{ order_by depth: 1, order: 1, name: 1 }

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

  def uploadable?(cur_user)
    return true if cur_user.gws_role_permissions["edit_other_gws_share_files_#{site.id}"] || owned?(cur_user)
    false
  end

  def quota_bytes
    share_max_folder_size.to_i
  end

  def quota_label
    h = ApplicationController.helpers
    if quota_bytes > 0
      "#{h.number_to_human_size(descendants_total_file_size)}/#{h.number_to_human_size(quota_bytes)}"
    else
      "#{h.number_to_human_size(descendants_total_file_size)}"
    end
  end

  def quota_over?
    return false if quota_bytes <= 0
    descendants_total_file_size >= quota_bytes
  end

  def quota_percentage
    return 0 if quota_bytes <= 0
    percentage = (descendants_total_file_size.to_f / quota_bytes.to_f) * 100
    percentage > 100 ? 100 : percentage
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
