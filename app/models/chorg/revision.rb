class Chorg::Revision
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::Permission
  include Voice::Lockable

  set_permission_name "cms_users", :edit

  attr_accessor :add_newly_created_group_to_site

  seqid :id
  field :name, type: String
  has_many :changesets, class_name: "Chorg::ChangeSet", dependent: :destroy
  field :job_ids, type: Array
  permit_params :name, :changesets, :add_newly_created_group_to_site
  validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: :site_id }

  def add_change_sets
    changesets.select { |e| e.type == Chorg::ChangeSet::TYPE_ADD }
  end

  def move_change_sets
    changesets.select { |e| e.type == Chorg::ChangeSet::TYPE_MOVE }
  end

  def unify_change_sets
    changesets.select { |e| e.type == Chorg::ChangeSet::TYPE_UNIFY }
  end

  def division_change_sets
    changesets.select { |e| e.type == Chorg::ChangeSet::TYPE_DIVISION }
  end

  def delete_change_sets
    changesets.select { |e| e.type == Chorg::ChangeSet::TYPE_DELETE }
  end
end
