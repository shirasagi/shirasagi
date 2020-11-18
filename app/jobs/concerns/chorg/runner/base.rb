module Chorg::Runner::Base
  extend ActiveSupport::Concern

  included do
    before_perform do
      @config = self.class.config_p.call
      @models = @config.models.map(&:constantize).freeze
      build_exclude_fields(@config.exclude_fields)
    end
  end

  def perform(name, opts)
    @cur_site = self.site
    @cur_user = self.user
    @adds_group_to_site = opts['newly_created_group_to_site'].presence == 'add'
    @gws_staff_record = opts['gws_staff_record']
    @item = self.class.revision_class.site(@cur_site).find_by(name: name)
    @item = self.class.revision_class.acquire_lock(@item, 1.hour)
    unless @item
      put_log("already running")
      return
    end

    self.class.revision_class.ensure_release_lock(@item) do
      init_context(opts)

      run_primitive_chorg

      put_log("==update_all==")
      with_inc_depth { update_all }

      put_log("==validate_all==")
      with_inc_depth { validate_all }

      # put_log("==delete_groups==")
      task.log("==削除==")
      with_inc_depth { delete_groups(delete_group_ids) }

      # put_log("==results==")
      task.log("==結果==")
      with_inc_depth do
        results.keys.each do |key|
          # put_log("#{key}: success=#{results[key]["success"]}, failed=#{results[key]["failed"]}")
          msg = [
            "[#{I18n.t("chorg.views.revisions/edit.#{key}")}]",
            "成功: #{results[key]["success"]},",
            "失敗: #{results[key]["failed"]}"
          ].join(' ')
          task.log("  #{msg}")
        end
      end

      finalize_context

      import_user_csv
    end
  end

  private

  def models_scope
    {}
  end

  def update_all
    return if substituter.empty?
    with_entity_updates(@models, substituter, models_scope) do |entity, updates|
      next if updates.blank?

      put_log("#{entity_title(entity)} has some updates. module=#{entity.class}")
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
      update(entity, updates)
      save_or_collect_errors(entity)
    end
  end

  def entity_title(entity)
    title = ''
    if entity.respond_to?(:name)
      title << entity.name
    end
    if entity.respond_to?(:url)
      title << '('
      title << entity.url
      title << ')'
    end
    title
  end

  def validate_all
    return if validation_substituter.empty?
    with_entity_updates(@models, validation_substituter, models_scope) do |entity, deletes|
      put_log("#{entity.name}(#{entity.url}) has deleted attributes: #{deletes}") if deletes.present?
    end
  end
end
