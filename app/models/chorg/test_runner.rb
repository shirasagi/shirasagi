class Chorg::TestRunner < Chorg::Runner
  include Job::Worker

  private
    def save_or_collect_errors(entity)
      return true if entity.valid?

      entity.errors.full_messages.each do |message|
        put_error("#{message}")
      end
      false
    rescue ScriptError, StandardError => e
      Rails.logger.fatal("got error while saving #{entity.class}(id = #{entity.id})")
      raise
    end

    def delete_entity(_)
      true
    end

    def move_users_group(_, _)

    end
end
