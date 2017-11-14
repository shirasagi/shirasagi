class Gws::Chorg::Task
  include SS::Model::Task
  include Gws::Addon::Chorg::EntityLog

  belongs_to :group, class_name: 'Gws::Group'
  belongs_to :revision, class_name: 'Gws::Chorg::Revision'

  validates :group_id, presence: true

  scope :group, ->(group) { where(group_id: group.id) }
  scope :and_revision, ->(revision) { where(revision_id: revision.id) }
  # override scope
  scope :site, ->(group) { group(group) }
end
