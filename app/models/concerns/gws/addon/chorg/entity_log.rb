module Gws::Addon::Chorg::EntityLog
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :entity_logs, type: Array
  end

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