module Cms::Addon
  module File
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :files, class_name: "SS::File"
      permit_params file_ids: []

      define_model_callbacks :clone_files

      before_save :clone_files, if: ->{ try(:new_clone?) }
      before_save :save_files
      around_save :update_file_owners
      after_save :put_contains_urls_logs
      after_destroy :destroy_files

      after_generate_file :generate_public_files if respond_to?(:after_generate_file)
      after_remove_file :remove_public_files if respond_to?(:after_remove_file)
    end

    module Utils
      extend SingleForwardable

      module_function

      delegate [:owner_item, :file_owned?] => SS::Relation::File::Utils

      def each_file(file_ids, &block)
        file_ids.each_slice(20) do |ids|
          SS::File.in(id: ids).to_a.map(&:becomes_with_model).each(&block)
        end
      end

      def attach_files(item, add_ids)
        owner_item = Utils.owner_item(item)
        cur_site = owner_item.cur_site if owner_item.respond_to?(:cur_site)
        cur_site ||= owner_item.site if owner_item.respond_to?(:site)
        cur_user = owner_item.cur_user if owner_item.respond_to?(:cur_user)
        is_branch = owner_item.respond_to?(:branch?) && owner_item.branch?

        ids = []
        Utils.each_file(item.file_ids) do |file|
          if !owner_item.allowed_other_user_files? && cur_user && cur_user.id != file.user_id
            # 他人のファイルを謝って添付することを防止する
            next
          end

          if add_ids && !add_ids.include?(file.id)
            # もともとから添付されていたファイルについては、必要であれば state を変更する
            file.update(state: owner_item.state) if owner_item.state_changed?
            ids << file.id
            next
          end

          # ここから新規に追加されたファイルの処理

          if Utils.file_owned?(file, owner_item)
            # すでに自分自身が所有している場合は、必要であれば state を変更する
            file.update(state: owner_item.state) if owner_item.state_changed?
            ids << file.id
            next
          end

          # 差し替えページの場合、ファイルの所有者が差し替え元なら、そのままとする
          if is_branch && Utils.file_owned?(file, owner_item.master)
            ids << file.id
            next
          end

          result = file.update(site: cur_site, model: owner_item.model_name.i18n_key, owner_item: owner_item, state: owner_item.state)
          if result
            file = file.becomes_with_model
            History::Log.build_file_log(file, site_id: cur_site.try(:id), user_id: cur_user.try(:id)).tap do |history|
              history.action = "update"
              history.behavior = "attachment"
              history.save
            end

            ids << file.id
          end
        end

        ids
      end

      def delete_files(item, del_ids)
        owner_item = Utils.owner_item(item)
        cur_site = owner_item.cur_site if owner_item.respond_to?(:cur_site)
        cur_site ||= owner_item.site if owner_item.respond_to?(:site)
        cur_user = owner_item.cur_user if owner_item.respond_to?(:cur_user)
        is_branch = owner_item.respond_to?(:branch?) && owner_item.branch?

        Utils.each_file(del_ids) do |file|
          if is_branch
            # 差し替えページの場合、差し替え元と共有している可能性がある。共有している場合は削除しないようにする。
            next if !Utils.file_owned?(file, owner_item) && Utils.file_owned?(file, owner_item.master)
          end

          if [ file, owner_item ].all? { |obj| obj.respond_to?(:skip_history_trash) }
            file.skip_history_trash = owner_item.skip_history_trash
          end
          file.cur_user = cur_user if file.respond_to?(:cur_user=) && cur_user
          result = file.destroy
          if result
            History::Log.build_file_log(file, site_id: cur_site.try(:id), user_id: cur_user.try(:id)).tap do |history|
              history.action = "destroy"
              history.behavior = "attachment"
              history.save
            end
          end
        end
      end
    end

    def allow_other_user_files
      @allowed_other_user_files = true
    end

    def allowed_other_user_files?
      @allowed_other_user_files == true
    end

    def save_files
      add_ids = file_ids - file_ids_was.to_a
      ids = Utils.attach_files(self, add_ids)
      self.file_ids = ids

      del_ids = file_ids_was.to_a - ids
      Utils.delete_files(self, del_ids)
    end

    def destroy_files
      owner_item = Utils.owner_item(self)
      is_branch = owner_item.respond_to?(:branch?) && owner_item.branch?

      Utils.each_file(file_ids) do |file|
        if is_branch
          # 差し替えページの場合、差し替え元と共有している可能性がある。共有している場合は削除しないようにする。
          next if !Utils.file_owned?(file, owner_item) && Utils.file_owned?(file, owner_item.master)
        end

        result = file.destroy
        if result
          History::Log.build_file_log(file, site_id: @cur_site.try(:id), user_id: @cur_user.try(:id)).tap do |history|
            history.action = "destroy"
            history.behavior = "attachment"
            history.save
          end
        end
      end
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

    private

    def update_file_owners
      is_new = new_record?
      yield

      return if !is_new

      update_owner_item_of_files
    end

    def update_owner_item_of_files
      owner_item = Utils.owner_item(self)
      is_branch = owner_item.respond_to?(:branch?) && owner_item.branch?

      Utils.each_file(file_ids) do |file|
        next if Utils.file_owned?(file, owner_item)

        # 差し替えページの場合、所有者を差し替え元のままとする
        next if is_branch && Utils.file_owned?(file, owner_item.master)

        file.update(owner_item: self)
      end
    end

    def put_contains_urls_logs
      add_contains_urls = self.contains_urls - self.contains_urls_was.to_a
      add_contains_urls.each do |file_url|
        item = History::Log.build_file_log(nil, site_id: @cur_site.try(:id), user_id: @cur_user.try(:id))
        item.url = file_url
        item.action = "update"
        item.behavior = "paste"
        item.ref_coll = "ss_files"
        item.save
      end

      del_contains_urls = self.contains_urls_was.to_a - self.contains_urls
      del_contains_urls.each do |file_url|
        item = History::Log.build_file_log(nil, site_id: @cur_site.try(:id), user_id: @cur_user.try(:id))
        item.url = file_url
        item.action = "destroy"
        item.behavior = "paste"
        item.ref_coll = "ss_files"
        item.save
      end
    end
  end
end
