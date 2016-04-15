module Gws::Addon
  module File
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :files, class_name: "SS::File"
      permit_params file_ids: []

      #before_save :clone_files, if: ->{ try(:new_clone?) }
      before_save :save_files
      after_destroy :destroy_files

      define_model_callbacks :save_files, :destroy_files
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
          else
            file.update_attributes(site_id: site_id, model: model_name.i18n_key, state: state)
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
    end

    def destroy_files
      run_callbacks(:destroy_files) do
        files.destroy_all
      end
    end
  end
end
