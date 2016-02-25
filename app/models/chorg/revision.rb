class Chorg::Revision
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Voice::Lockable

  set_permission_name "chorg_revisions", :edit

  attr_accessor :add_newly_created_group_to_site

  seqid :id
  field :name, type: String
  field :job_ids, type: Array

  has_many :changesets, class_name: "Chorg::Changeset", dependent: :destroy

  permit_params :name, :changesets, :add_newly_created_group_to_site

  validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: :site_id }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }

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
