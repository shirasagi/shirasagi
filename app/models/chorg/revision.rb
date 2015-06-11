class Chorg::Revision
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Voice::Lockable

  set_permission_name "cms_users", :edit

  attr_accessor :add_newly_created_group_to_site

  seqid :id
  field :name, type: String
  has_many :changesets, class_name: "Chorg::Changeset", dependent: :destroy
  field :job_ids, type: Array
  permit_params :name, :changesets, :add_newly_created_group_to_site
  validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: :site_id }

  def add_changesets
    changesets.select { |e| e.type == Chorg::Changeset::TYPE_ADD }
  end

  def move_changesets
    changesets.select { |e| e.type == Chorg::Changeset::TYPE_MOVE }
  end

  def unify_changesets
    changesets.select { |e| e.type == Chorg::Changeset::TYPE_UNIFY }
  end

  def division_changesets
    changesets.select { |e| e.type == Chorg::Changeset::TYPE_DIVISION }
  end

  def delete_changesets
    changesets.select { |e| e.type == Chorg::Changeset::TYPE_DELETE }
  end
end
