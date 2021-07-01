module SS::Relation::FileHistory
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    has_many :history_files, class_name: "SS::HistoryFile", foreign_key: :original_id, dependent: :destroy
    after_destroy :destroy_history_files
  end

  def save_history_file
    source = history_file_instance

    now = Time.zone.now
    source.original_id = self.id
    source.created = now
    source.updated = now
    source.state = "closed"

    source.class.create_empty!(source.attributes) do |new_file|
      ::FileUtils.copy(self.path, new_file.path)
      new_file.disable_thumb = true
      new_file.save!
    end

    max_age = 10
    history_files.skip(max_age).destroy
  rescue => e
    Rails.logger.fatal("save_history_file failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def destroy_history_files
    history_files.destroy_all
  end

  private

  def history_file_instance
    safe_attributes = attributes.to_h.select{ |k| SS::HistoryFile.fields.key?(k) }
    # COPY_SKIP_ATTRS
    %w(_id id model file_id thumb_id in_file).each { |k| safe_attributes.delete(k) }

    SS::HistoryFile.new(safe_attributes)
  end
end
