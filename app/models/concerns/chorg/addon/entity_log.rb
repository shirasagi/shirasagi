module Chorg::Addon::EntityLog
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    after_destroy :delete_entity_log
  end

  def entity_log_path
    "#{SS::File.root}/chorg_tasks/" + id.to_s.split(//).join("/") + "/_/entity_logs.log"
  end

  def entity_logs
    @entity_logs ||= begin
      logs = []
      if ::File.exists?(entity_log_path)
        ::File.foreach(entity_log_path) do |line|
          logs << JSON.parse(line)
        end
      end
      logs
    end
  end

  def init_entity_logs
    ::FileUtils.rm_f(entity_log_path)
    dirname = ::File.dirname(entity_log_path)
    ::FileUtils.mkdir_p(dirname) if !Dir.exists?(dirname)

    @entity_log_file = ::File.open(entity_log_path, 'w')
    @entity_log_file.sync = true
  end

  def finalize_entity_logs
    @entity_log_file.close if @entity_log_file
  end

  def delete_entity_log
    ::FileUtils.rm_f(entity_log_path)
  end

  def overwrite_fields
    %w(contact_tel contact_fax contact_email contact_link_url contact_link_name)
  end

  def store_entity_changes(entity)
    if entity.persisted?
      changes = entity.changes.except('_id', 'created', 'updated')
      overwrite_fields.each do |k|
        changes[k] ||= [entity[k], entity[k]] if entity.respond_to?(k)
      end
      hash = { 'id' => entity.id.to_s, 'model' => entity.class.name, 'changes' => changes }
    else
      creates = entity.attributes.except('_id', 'created', 'updated')
      hash = { 'model' => entity.class.name, 'creates' => creates }
    end
    @entity_log_file.puts(hash.to_json)
  end

  def store_entity_deletes(entity)
    deletes = entity.attributes.except('_id', 'created', 'updated')
    hash = { 'id' => entity.id.to_s, 'model' => entity.class.name, 'deletes' => deletes }
    @entity_log_file.puts(hash.to_json)
  end

  def store_entity_errors(entity)
    hash = { 'id' => entity.id.to_s, 'model' => entity.class.name, 'errors' => entity.errors.full_messages }
    @entity_log_file.puts(hash.to_json)
  end
end
