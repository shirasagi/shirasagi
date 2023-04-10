module Gws::Addon::Share
  module History
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      after__save_file :save_history_file if defined?(:after__save_file)
      after_save :save_history_for_save
      after_destroy :destroy_all_histories
    end

    def histories
      @histroies ||= Gws::Share::History.where(model: reference_model, item_id: id)
    end

    def skip_gws_history
      @skip_gws_history = true
    end

    def save_history_file
      Fs.cp(path, path + "_history#{next_history_file_id}") if Fs.exist?(path)
    end

    private

    def current_history_file_id
      base = path + "_history"
      Fs.glob("#{base}[0-9]*").map { |path| path[base.length..-1].to_i }.max
    end

    def next_history_file_id
      current = current_history_file_id
      current.nil? ? 0 : current + 1
    end

    def save_history_for_save
      field_changes = changes.presence || previous_changes
      return if field_changes.blank?

      if field_changes.key?('deleted')
        if deleted.present?
          save_history mode: 'delete'
        else
          save_history mode: 'undelete'
        end
      elsif histories.blank?
        save_history mode: 'create'
      else
        save_history mode: 'update', updated_fields: field_changes.keys.reject { |s| s =~ /_hash$/ }
      end
    end

    def destroy_all_histories
      histories.destroy_all
    end

    def save_history(overwrite_params = {})
      return if @skip_gws_history

      site_id = @cur_site.try(:id)
      site_id ||= self.site_id rescue nil
      return unless site_id

      save_history_file if current_history_file_id.nil?

      srcname = "history#{current_history_file_id}" if current_history_file_id

      item = Gws::Share::History.new(
        cur_user: @cur_user,
        site_id: site_id,
        name: reference_name,
        model: reference_model,
        uploadfile_name: name,
        uploadfile_filename: filename,
        uploadfile_srcname: srcname,
        uploadfile_size: size,
        uploadfile_content_type: content_type,
        item_id: id
      )
      item.attributes = overwrite_params
      item.save

      # remove old histories
      if Gws::Share::History.max_count > 0
        histories.skip(Gws::Share::History.max_count).destroy_all
      end
    end
  end
end
