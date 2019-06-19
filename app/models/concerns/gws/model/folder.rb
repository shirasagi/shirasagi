module Gws::Model::Folder
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::Fields::DependantNaming

  included do
    seqid :id
    field :name, type: String
    field :depth, type: Integer
    field :order, type: Integer, default: 0
    field :state, type: String, default: "closed"
    attr_accessor :in_basename, :in_parent

    permit_params :name, :order, :in_basename, :in_parent

    before_validation :set_depth, if: ->{ name.present? }
    before_validation :set_name_and_depth, if: ->{ in_basename.present? }

    validates :name, presence: true, length: {maximum: 80}
    validates :order, numericality: {less_than_or_equal_to: 999_999}
    validates :in_basename, length: {maximum: 80}
    validates :in_basename, format: { with: /\A[^\\\/:*?"<>|]*\z/, message: :invalid_chars_as_name }

    validate :validate_parent_name
    validate :validate_rename_children,
             :validate_children_move_to_other_parent, if: ->{ self.attributes["action"] == "update" }

    validate :validate_folder_name, if: ->{ self.attributes["action"] =~ /create|update/ }

    before_destroy :validate_children

    after_save :rename_children, if: ->{ @db_changes }

    default_scope ->{ order_by depth: 1, order: 1, name: 1 }

    scope :sub_folder, ->(key, folder) {
      if key.start_with?('root_folder')
        where("$and" => [ {name: /^(?!.*\/).*$/} ] )
      else
        where("$and" => [ {name: /^#{folder}\/(?!.*\/).*$/} ] )
      end
    }
  end

  module ClassMethods
    def search(params)
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    end

    def tree_sort(options = {})
      SS::TreeList.build self, options
    end
  end

  def trailing_name
    @trailing_name ||= name.split("/")[depth-1..-1].join("/") if name.present?
  end

  def parent
    @parent ||= begin
      if name.present?
        parent_name = ::File.dirname(name)
        dependant_scope.where(name: parent_name).first
      end
    end
  end

  def parents
    @parents ||= begin
      paths = split_path(name.sub(/^\//, ''))
      paths.pop
      dependant_scope.in(name: paths)
    end
  end

  def split_path(path)
    last = nil
    dirs = path.split('/').map { |n| last = last ? "#{last}/#{n}" : n }
  end

  def folders
    self.class.where(site_id: site_id, name: /^#{name}\//)
  end

  def children(cond = {})
    folders.where cond.merge(depth: depth + 1)
  end

  def uploadable?(cur_user)
    return true if cur_user.gws_role_permissions["edit_other_gws_share_files_#{site.id}"] || owned?(cur_user)
    false
  end

  private

  def set_name_and_depth
    if in_parent.present?
      parent_folder = dependant_scope.find(in_parent) rescue nil
    end

    if parent_folder.present?
      self.name = "#{parent_folder.name}/#{in_basename}"
    else
      self.name = in_basename
    end

    set_depth
  end

  def set_depth
    self.depth = name.count('/') + 1 unless name.nil?
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
      errors.add :base, :not_found_parent unless dependant_scope.where(name: ::File.dirname(name)).exists?
    end
  end

  def validate_rename_children
    if self.attributes["before_folder_name"].include?("/") && !self.name.include?("/")
      errors.add :base, :not_move_to_parent
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
    if name.present? && dependant_scope.where(name: /^#{::Regexp.escape(name)}\//).exists?
      errors.add :base, :found_children
      return false
    end
    true
  end

  def validate_folder_name
    if self.id == 0
      errors.add :base, :not_create_same_folder if dependant_scope.where(name: self.name).first
    end

    if self.id != 0
      if dependant_scope.where(name: self.name).present? && dependant_scope.where(id: self.id).first.name != self.name
        errors.add :base, :not_move_to_same_name_folder
      end
    end
    true
  end

  def rename_children
    return unless @db_changes["name"]
    return unless @db_changes["name"][0]

    src = @db_changes["name"][0]
    dst = @db_changes["name"][1]

    folder_ids = self.class.where(site_id: site_id, name: /^#{src}\//).pluck(:id)
    folder_ids.each do |id|
      folder = self.class.where(id: id).first
      next unless folder

      folder.name = folder.name.sub(/^#{src}\//, "#{dst}/")
      folder.save(validate: false)
    end
  end
end
