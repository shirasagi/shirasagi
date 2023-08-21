module Cms::Reference::Files
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    embeds_ids :files, class_name: "SS::File"
    permit_params file_ids: []

    define_model_callbacks :clone_files

    after_merge_branch :transfer_owner_from_branch if respond_to?(:after_merge_branch)
    before_save :clone_files, if: ->{ try(:new_clone?) }
    before_save :save_files
    around_save :update_file_owners
    after_save :put_contains_urls_logs
    after_destroy :destroy_files

    after_generate_file :generate_public_files if respond_to?(:after_generate_file)
    after_remove_file :remove_public_files if respond_to?(:after_remove_file)
  end

  def allow_other_user_files
    @allowed_other_user_files = true
  end

  def allowed_other_user_files?
    @allowed_other_user_files == true
  end

  def transfer_owner_from_branch
    return unless in_branch

    owner_item = SS::Model.container_of(self)
    SS::File.each_file(file_ids) do |file|
      if file.owner_item_id == in_branch.id && file.owner_item_type == in_branch.class.name
        # 差し替えページがファイルを所有しているので、所有者を変更
        file.update(owner_item: owner_item)
      end
    end
  end

  def save_files
    file_ids_was = self.file_ids_was.to_a
    add_ids = file_ids - file_ids_was
    on_clone_file = method(:update_html_with_clone_file) if respond_to?(:update_html_with_clone_file)
    ids = Cms::Reference::Files::Utils.attach_files(self, add_ids, on_clone_file: on_clone_file)
    self.file_ids = ids

    del_ids = file_ids_was - ids
    Cms::Reference::Files::Utils.delete_files(self, del_ids) if del_ids.present?
  end

  def destroy_files
    owner_item = SS::Model.container_of(self)
    is_branch = owner_item.respond_to?(:branch?) && owner_item.branch?

    SS::File.each_file(file_ids) do |file|
      if is_branch
        # 差し替えページの場合、差し替え元と共有している可能性がある。共有している場合は削除しないようにする。
        next if !SS::File.file_owned?(file, owner_item) && SS::File.file_owned?(file, owner_item.master)
      end

      result = file.destroy
      next unless result

      History::Log.build_file_log(file, site_id: @cur_site.try(:id), user_id: @cur_user.try(:id)).tap do |history|
        history.action = "destroy"
        history.behavior = "attachment"
        history.save
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
    owner_item = SS::Model.container_of(self)
    is_branch = owner_item.respond_to?(:branch?) && owner_item.branch?

    SS::File.each_file(file_ids) do |file|
      next if SS::File.file_owned?(file, owner_item)

      # 差し替えページの場合、所有者を差し替え元のままとする
      next if is_branch && SS::File.file_owned?(file, owner_item.master)

      file.update(owner_item: owner_item)
    end
  end

  def put_contains_urls_logs
    return if !respond_to?(:contains_urls)

    add_contains_urls = self.contains_urls - self.contains_urls_previously_was.to_a
    add_contains_urls.each do |file_url|
      item = History::Log.build_file_log(nil, site_id: @cur_site.try(:id), user_id: @cur_user.try(:id))
      item.url = file_url
      item.action = "update"
      item.behavior = "paste"
      item.ref_coll = "ss_files"
      item.save
    end

    del_contains_urls = self.contains_urls_previously_was.to_a - self.contains_urls
    del_contains_urls.each do |file_url|
      item = History::Log.build_file_log(nil, site_id: @cur_site.try(:id), user_id: @cur_user.try(:id))
      item.url = file_url
      item.action = "destroy"
      item.behavior = "paste"
      item.ref_coll = "ss_files"
      item.save
    end
  end

  module Utils
    extend SingleForwardable

    module_function

    EMPTY_ARRAY = [].freeze

    def other_user_owned?(file, cur_user)
      cur_user && cur_user.id != file.user_id
    end

    def need_to_clone?(file, owner_item, branch)
      return false if file.owner_item_id.blank? || file.owner_item.blank?
      return false if file.owner_item == owner_item
      return false if branch && file.owner_item == branch

      true
    end

    def attach_files(item, add_ids, branch: nil, on_clone_file: nil)
      owner_item = SS::Model.container_of(item)
      cur_site = owner_item.cur_site if owner_item.respond_to?(:cur_site)
      cur_site ||= owner_item.site if owner_item.respond_to?(:site)
      cur_user = owner_item.cur_user if owner_item.respond_to?(:cur_user)
      is_allowed_other_user_files = owner_item.allowed_other_user_files?
      is_branch = owner_item.respond_to?(:branch?) && owner_item.branch?
      add_ids ||= Utils::EMPTY_ARRAY

      ids = []
      SS::File.each_file(item.file_ids) do |file|
        if !add_ids.include?(file.id) || SS::File.file_owned?(file, owner_item)
          # もともとから添付されていたファイル、または、すでに自分自身が所有している場合、必要であれば state を変更する
          file.update(state: owner_item.try(:state) || "closed") if owner_item.try(:state_changed?)
          ids << file.id
          next
        end

        # 差し替えページの場合、ファイルの所有者が差し替え元なら、そのままとする
        if is_branch && SS::File.file_owned?(file, owner_item.master)
          ids << file.id
          next
        end

        # ここから新規ファイルの添付処理
        #
        # 既存ファイルの場合はどのユーザーが所有していようと関係ないが、
        # 新規ファイルの場合、自ユーザーのファイルしか添付することはできない。
        # 他ユーザーのファイルを誤って添付することを防止する
        next if !is_allowed_other_user_files && Utils.other_user_owned?(file, cur_user)

        # ファイルの所有者が存在している場合、誤って所有者を変更することを防止する目的で、ファイルを複製する
        # ただし、ブランチが所有している場合を除く
        if Utils.need_to_clone?(file, owner_item, branch)
          clone_file = SS::File.clone_file(file, cur_user: cur_user, owner_item: owner_item)
          ids << clone_file.id
          on_clone_file.call(file, clone_file) if on_clone_file
          next
        end

        # ファイルの所有者などを更新する
        result = file.update(
          site: cur_site, model: owner_item.model_name.i18n_key, owner_item: owner_item, state: owner_item.try(:state) || "closed"
        )
        next unless result

        file = file.becomes_with_model
        History::Log.build_file_log(file, site_id: cur_site.try(:id), user_id: cur_user.try(:id)).tap do |history|
          history.action = "update"
          history.behavior = "attachment"
          history.save
        end

        ids << file.id
      end

      ids
    end

    def delete_files(item, del_ids)
      owner_item = SS::Model.container_of(item)
      cur_site = owner_item.cur_site if owner_item.respond_to?(:cur_site)
      cur_site ||= owner_item.site if owner_item.respond_to?(:site)
      cur_user = owner_item.cur_user if owner_item.respond_to?(:cur_user)
      is_branch = owner_item.respond_to?(:branch?) && owner_item.branch?

      SS::File.each_file(del_ids) do |file|
        if is_branch
          # 差し替えページの場合、差し替え元と共有している可能性がある。共有している場合は削除しないようにする。
          next if !SS::File.file_owned?(file, owner_item) && SS::File.file_owned?(file, owner_item.master)
        end

        if [ file, owner_item ].all? { |obj| obj.respond_to?(:skip_history_trash) }
          file.skip_history_trash = owner_item.skip_history_trash
        end
        file.cur_user = cur_user if file.respond_to?(:cur_user=) && cur_user
        result = file.destroy
        next unless result

        History::Log.build_file_log(file, site_id: cur_site.try(:id), user_id: cur_user.try(:id)).tap do |history|
          history.action = "destroy"
          history.behavior = "attachment"
          history.save
        end
      end
    end
  end
end
