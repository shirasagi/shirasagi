class Gws::Chorg::Task
  include SS::Model::Task

  belongs_to :group, class_name: 'Gws::Group'
  field :entity_logs, type: Array
  belongs_to :revision, class_name: 'Gws::Chorg::Revision'

  validates :group_id, presence: true

  scope :group, ->(group) { where(group_id: group.id) }
  scope :and_revision, ->(revision) { where(revision_id: revision.id) }
  # override scope
  scope :site, ->(group) { group(group) }

  def init_entity_logs
    self.unset(:entity_logs)
    self.entity_logs = []
  end

  def store_entity_changes(entity)
    if entity.persisted?
      changes = entity.changes.except('_id', 'created', 'updated')
      self.entity_logs << { 'id' => entity.id.to_s, 'model' => entity.class.name, 'changes' => changes }
    else
      creates = entity.attributes.except('_id', 'created', 'updated')
      self.entity_logs << { 'model' => entity.class.name, 'creates' => creates }
    end
  end

  def store_entity_deletes(entity)
    deletes = entity.attributes.except('_id', 'created', 'updated')
    self.entity_logs << { 'id' => entity.id.to_s, 'model' => entity.class.name, 'deletes' => deletes }
  end

  def store_entity_errors(entity)
    self.entity_logs << { 'id' => entity.id.to_s, 'model' => entity.class.name, 'errors' => entity.errors.full_messages }
  end
end
