module Chorg::Runner::Test
  extend ActiveSupport::Concern

  private

  def save_or_collect_errors(entity)
    if entity.valid?
      task.store_entity_changes(entity)
      true
    else
      entity.errors.full_messages.each do |message|
        put_error(message.to_s)
      end
      task.store_entity_errors(entity)
      false
    end
  rescue ScriptError, StandardError => e
    Rails.logger.fatal("got error while saving #{entity.class}(id = #{entity.id})")
    raise
  end

  def delete_entity(entity)
    task.store_entity_deletes(entity)
    true
  end

  def move_users_group(_, _)
  end
end
