class Chorg::Task
  include SS::Model::Task
  include Chorg::Addon::EntityLog

  belongs_to :revision, class_name: 'Chorg::Revision'

  scope :and_revision, ->(revision) { where(revision_id: revision.id) }
end
