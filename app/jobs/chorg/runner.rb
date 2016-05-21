class Chorg::Runner < Cms::ApplicationJob
  include Chorg::Context
  include Chorg::Loggable
  include Chorg::MongoidSupport
  include Chorg::PrimitiveRunner

  MAIN = "main".freeze
  TEST = "test".freeze

  def self.job_class(type)
    case type
    when MAIN then
      Chorg::MainRunner
    when TEST then
      Chorg::TestRunner
    else
      nil
    end
  end

  before_perform do
    config = SS.config.chorg
    @config = config
    @models = config.models.map(&:constantize).freeze
    build_exclude_fields(config.exclude_fields)
  end

  def perform(name, adds_group_to_site)
    @cur_site = self.site
    @cur_user = self.user
    @adds_group_to_site = adds_group_to_site
    @item = Chorg::Revision.site(@cur_site).find_by(name: name)
    @item = Chorg::Revision.acquire_lock(@item, 1.hour.from_now)
    unless @item
      put_log("already running")
      return
    end

    Chorg::Revision.ensure_release_lock(@item) do
      init_context

      run_primitive_chorg

      put_log("==update_all==")
      with_inc_depth { update_all }

      put_log("==validate_all==")
      with_inc_depth { validate_all }

      put_log("==delete_groups==")
      with_inc_depth { delete_groups(delete_group_ids) }

      put_log("==results==")
      with_inc_depth do
        results.keys.each do |key|
          put_log("#{key}: success=#{results[key]["success"]}, failed=#{results[key]["failed"]}")
        end
      end
    end
  end

  private
    def update_all
      return if substituter.empty?
      with_all_entity_updates(@models, substituter) do |entity, updates|
        next if updates.blank?

        put_log("#{entity.name}(#{entity.url}) has some updates. module=#{entity.class}")
        with_inc_depth do
          updates = updates.select { |k, v| v.present? }
          updates.each do |k, new_value|
            old_value = entity[k]
            put_log("property #{k} has these changes:")
            with_inc_depth do
              if new_value.is_a?(String)
                Diffy::Diff.new(old_value, new_value, diff: "-U 3").to_s.each_line do |line|
                  next if /No newline at end of file/i =~ line
                  put_log(line.chomp.to_s)
                end
              elsif new_value.is_a?(Array)
                convert_to_group_names(old_value - new_value).each do |name|
                  put_log("-#{name}")
                end
                convert_to_group_names(new_value - old_value).each do |name|
                  put_log("+#{name}")
                end
              else
                convert_to_group_names([old_value]).each do |name|
                  put_log("-#{name}")
                end
                convert_to_group_names([new_value]).each do |name|
                  put_log("+#{name}")
                end
              end
            end
          end
        end
        update_attributes(entity, updates)
        save_or_collect_errors(entity)
      end
    end

    def validate_all
      return if validation_substituter.empty?
      with_all_entity_updates(@models, validation_substituter) do |entity, deletes|
        put_log("#{entity.name}(#{entity.url}) has deleted attributes: #{deletes}") if deletes.present?
      end
    end
end
