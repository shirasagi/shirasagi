module Member::Addon
  module File
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :files, class_name: "SS::File"
      permit_params file_ids: []

      before_save :save_files
      after_save :put_contains_urls_logs
      after_destroy :destroy_files

      #after_save :generate_public_files, if: ->{ public? }
      #after_save :remove_public_files, if: ->{ !public? }
    end

    def allow_other_user_files
      @allowed_other_user_files = true
    end

    def allowed_other_user_files?
      @allowed_other_user_files == true
    end

    def save_files
      add_ids = file_ids - file_ids_was.to_a

      ids = []
      files.each do |file|
        if !add_ids.include?(file.id)
          file.update(owner_item: self, state: state) if state_changed?
        elsif !allowed_other_user_files? && @cur_user && @cur_user.id != file.user_id
          next
        else
          file.update(site_id: site_id, model: model_name.i18n_key, owner_item: self, state: state)
          item = create_history_log(file)
          item.action = "update"
          item.behavior = "attachment"
          item.save
        end
        ids << file.id
      end
      self.file_ids = ids

      del_ids = file_ids_was.to_a - ids
      del_ids.each do |id|
        file = SS::File.where(id: id).first
        file.cur_user = @cur_user if file.respond_to?(:cur_user=) && @cur_user
        file.destroy if file
        item = create_history_log(file)
        item.action = "destroy"
        item.behavior = "attachment"
        item.save
      end
    end

    def destroy_files
      files.destroy_all
    end

    def generate_public_files
      files.each do |file|
        file.generate_public_file
      end
    end

    def remove_public_files
      files.each do |file|
        file.remove_public_file
      end
    end

    def create_history_log(file)
      site_id = nil
      user_id = nil
      site_id = @cur_site.id if @cur_site.present?
      user_id = @cur_user.id if @cur_user.present?
      History::Log.new(
        site_id: site_id,
        user_id: user_id,
        session_id: Rails.application.current_session_id,
        request_id: Rails.application.current_request_id,
        controller: self.model_name.i18n_key,
        url: file.try(:url),
        page_url: Rails.application.current_path_info,
        ref_coll: file.try(:collection_name)
      )
    end

    def put_contains_urls_logs
      add_contains_urls = self.contains_urls - self.contains_urls_was.to_a
      add_contains_urls.each do |file|
        item = create_history_log(file)
        item.url = file
        item.action = "update"
        item.behavior = "paste"
        item.save
      end

      del_contains_urls = self.contains_urls_was.to_a - self.contains_urls
      del_contains_urls.each do |file|
        item = create_history_log(file)
        item.url = file
        item.action = "destroy"
        item.behavior = "paste"
        item.save
      end
    end
  end
end
