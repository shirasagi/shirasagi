module Chorg::Runner::Test
  extend ActiveSupport::Concern

  private

  def next_pseudo_id
    @next_id ||= (SS::Sequence.max(:value) || 0) + 1
    ret = @next_id
    @next_id += 1
    ret
  end

  def save_or_collect_errors(entity)
    if entity.new_record?
      entity.id = next_pseudo_id
    end

    if exclude_validation_model?(entity)
      put_log("save (skip validate) : #{entity.class}(#{entity.id})")
      task.store_entity_changes(entity, target_site(entity))
      true
    elsif entity.valid?
      put_log("save : #{entity.class}(#{entity.id})")
      task.store_entity_changes(entity, target_site(entity))
      true
    else
      put_error("save failed : #{entity.class}(#{entity.id}) #{entity.errors.full_messages.join(", ")}")
      task.store_entity_errors(entity, target_site(entity))
      false
    end
  rescue ScriptError, StandardError => e
    Rails.logger.fatal("got error while saving #{entity.class}(id = #{entity.id})")
    raise
  end

  def exclude_validation_model?(entity)
    @exclude_validation_models ||= begin
      SS.config.gws.chorg["exclude_validation_models"].map { |model| model.constantize }
    rescue
      []
    end
    @exclude_validation_models.include?(entity.class)
  end

  def delete_entity(entity)
    task.store_entity_deletes(entity, target_site(entity))
    true
  end

  def move_users_group(_from_id, _to_id)
  end

  def import_user_csv
  end
end
