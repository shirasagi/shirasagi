class Chorg::MainRunner < Chorg::Runner
  private
    def save_or_collect_errors(entity)
      return true if entity.save

      entity.errors.full_messages.each do |message|
        put_error(message.to_s)
      end
      false
    rescue ScriptError, StandardError => e
      Rails.logger.fatal("got error while saving #{entity.class}(id = #{entity.id})")
      raise
    end

    def delete_entity(entity)
      entity.delete
    end

    def move_users_group(from_id, to_id)
      substituter = Chorg::Substituter::IdSubstituter.new(from_id, to_id)
      with_all_entities([Cms::User]) do |user|
        old_ids = user.group_ids
        old_names = user.groups.pluck(:name).join(",")
        new_ids = substituter.call(user.group_ids)
        if old_ids != new_ids
          user.group_ids = new_ids
          save_or_collect_errors(user)
          new_names = user.groups.pluck(:name).join(",")
          put_log("moved user's group name=#{user.name}, from=#{old_names}, to=#{new_names}")
        end
      end
    end
end
