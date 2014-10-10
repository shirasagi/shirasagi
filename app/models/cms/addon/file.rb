module Cms::Addon
  module File
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 210

    included do
      embeds_ids :files, class_name: "SS::File"
      permit_params file_ids: []

      before_save :save_files
      after_destroy :destroy_files
    end

    def save_files
      return true unless file_ids_changed?

      add_ids = file_ids - file_ids_was.to_a

      ids = []
      files.each do |file|
        if !add_ids.include?(file.id)
          #
        elsif @cur_user && @cur_user.id != file.user_id
          next
        else
          file.update_attribute(:model, model_name.i18n_key)
          file.update_attribute(:site_id, site_id)
        end
        ids << file.id
      end
      self.file_ids = ids

      del_ids = file_ids_was.to_a - ids
      del_ids.each do |id|
        file = SS::File.where(id: id).first
        file.destroy if file
      end
    end

    def destroy_files
      files.destroy_all
    end
  end
end
