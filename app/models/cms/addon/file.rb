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

    def clone_files
      ids = SS::Extensions::Array.new
      files.each do |f|
        attr = Hash[f.attributes]
        attr.select!{ |k| f.fields.keys.include?(k) }

        file = SS::File.new(attr)
        file.id = nil
        file.in_file = f.uploaded_file

        if file.save
          ids << file.id.mongoize

          html = self.html
          html.gsub!("=\"#{f.url}\"", "=\"#{file.url}\"")
          html.gsub!("=\"#{f.thumb_url}\"", "=\"#{file.thumb_url}\"")
          self.html = html
        end
      end
      self.file_ids = ids
    end

    def destroy_files
      files.destroy_all
    end
  end
end
