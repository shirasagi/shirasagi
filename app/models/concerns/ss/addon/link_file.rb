module SS::Addon
  module LinkFile
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :ad

    included do
      attr_accessor :in_clone_file, :ref_file_ids, :link_urls

      embeds_ids :files, class_name: "SS::LinkFile"
      permit_params file_ids: [], ref_file_ids: [], link_urls: {}

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
        file_ids.select(&:numeric?).each do |file_id|
          file = SS::LinkFile.unscoped.where(id: file_id).first
          next if file.blank?

          file.update(link_url: link_urls[file.id.to_s]) if link_urls.present?
          if !add_ids.include?(file.id)
          elsif !allowed_other_user_files? && @cur_user && @cur_user.id != file.user_id
            next
          else
            file.update(model: "ss/link_file", owner_item: self, state: "public", site_id: nil)
          end
          ids << file.id
        end
        ids += save_ref_files
        self.attributes["file_ids"] = ids

        del_ids = file_ids_was.to_a - ids

        files = SS::LinkFile.where(:id.in => del_ids)
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
          file.owner_item = self
          file.state = "public"

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

        ss_file = SS::LinkFile.new
        ss_file.state = state
        ss_file.name = ref_file.name
        ss_file.model = model_name.i18n_key
        ss_file.user_id = @cur_user.try(:id) || try(:user_id)
        ss_file.site_id = @cur_site.try(:id) || try(:site_id)
        ss_file.in_file = file
        ss_file.owner_item = SS::Model.container_of(self)
        ss_file.state = "public"
        ss_file.save

        add_ids << ss_file.id
      end
      add_ids
    end
  end
end
