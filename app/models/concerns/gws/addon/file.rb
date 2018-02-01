module Gws::Addon
  module File
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_clone_file, :ref_file_ids
      embeds_ids :files, class_name: "SS::File"
      permit_params file_ids: [], ref_file_ids: []

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
        ids += save_ref_files
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

    def ref_files
      return [] if ref_file_ids.blank?

      files = []
      ref_file_ids.each do |ref_file_id|
        file = SS::File.find(ref_file_id) rescue nil
        files << file if file
      end
      files
    end

    private

    def save_ref_files
      add_ids = []
      ref_files.each do |ref_file|
        file = Fs::UploadedFile.new
        file.binmode
        file.write(ref_file.read)
        file.rewind
        file.original_filename = ref_file.filename

        ss_file = SS::File.new
        ss_file.state = state
        ss_file.name = ref_file.name
        ss_file.model = model_name.i18n_key
        ss_file.user_id = @cur_user.try(:id) || try(:user_id)
        ss_file.site_id = @cur_site.try(:id) || try(:site_id)
        ss_file.in_file = file
        ss_file.save

        add_ids << ss_file.id
      end
      add_ids
    end
  end
end
