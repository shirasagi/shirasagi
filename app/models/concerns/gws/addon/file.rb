module Gws::Addon
  module File
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_clone_file
      embeds_ids :files, class_name: "SS::File"
      permit_params file_ids: []

      before_save :clone_files, if: ->{ in_clone_file }
      before_save :save_files
      after_destroy :destroy_files

      define_model_callbacks :save_files, :clone_files, :destroy_files
    end

    def allow_other_user_files
      @allowed_other_user_files = true
    end

    def allowed_other_user_files?
      @allowed_other_user_files == true
    end

    def save_files
      run_callbacks(:save_files) do
        add_ids = file_ids - file_ids_was.to_a

        ids = []
        files.each do |file|
          if !add_ids.include?(file.id)
            file.update_attributes(state: state) if state_changed?
          elsif !allowed_other_user_files? && @cur_user && @cur_user.id != file.user_id
            next
          elsif file.model == "share/file"
            file.update_attributes(site_id: site_id, state: state)
          else
            file.update_attributes(site_id: site_id, model: model_name.i18n_key, state: state)
          end
          ids << file.id
        end
        self.attributes["file_ids"] = ids

        del_ids = file_ids_was.to_a - ids

        files = SS::File.where(:id.in => del_ids)
        files.each do |file|
          # Only unused file
          file.destroy unless self.class.where(:id.ne => id, file_ids: file.id).exists?
        end
      end
    end

    def clone_files
      run_callbacks(:clone_files) do
        ids = {}
        files.each do |f|
          attributes = Hash[f.attributes]
          attributes.slice!(*f.fields.keys)

          file = SS::File.new(attributes)
          file.id = nil
          file.in_file = f.uploaded_file
          file.user_id = @cur_user.id if @cur_user

          file.save validate: false
          ids[f.id] = file.id
        end
        self.file_ids = ids.values
        self.in_clone_file = ids
      end
    end

    def destroy_files
      run_callbacks(:destroy_files) do
        files.each do |file|
          # Only unused file
          file.destroy unless self.class.where(:id.ne => id, file_ids: file.id).exists?
        end
      end
    end
  end
end
