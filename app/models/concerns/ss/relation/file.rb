module SS::Relation::File
  extend ActiveSupport::Concern
  extend SS::Translation

  DEFAULT_FILE_CLASS_NAME = "SS::File".freeze
  DEFAULT_FILE_STATE = 'public'.freeze

  module ClassMethods
    def belongs_to_file(name, class_name: nil, presence: false, static_state: nil, resizing: nil, accepts: nil)
      class_name ||= DEFAULT_FILE_CLASS_NAME
      class_name = class_name.to_s

      belongs_to name.to_sym, class_name: class_name

      attr_accessor "in_#{name}", "rm_#{name}", "in_#{name}_resizing", "skip_#{name}_validate_relation"

      permit_params "#{name}_id", "in_#{name}", "rm_#{name}"
      permit_params "in_#{name}_resizing" => []

      define_model_callbacks "#{name}_save"

      if class_name != DEFAULT_FILE_CLASS_NAME
        # ss/temp_file （ファイルダイアログ上のファイル）を ss/logo_file に添付するようなケースの場合、relation が nil となる。
        # ss/logo_file は model が "ss/logo_file" のファイルを操作対象とするので model が "ss/temp_file" のファイルを操作できないため、
        # relation が nil となる。このようなケースに対応する。
        before_validation { Changes.ensure_to_have_relation(self, name) }
      end
      accepts = Changes.normalize_accepts(accepts) if accepts.present?
      validate { Changes.validate_relation(self, name, presence: presence, accepts: accepts) }
      before_save do
        Changes.save_relation_changes(self, name, class_name: class_name, default_resizing: resizing)
      end
      after_destroy { Changes.destroy_relation(self, name, send(name)) }
      if respond_to?(:after_merge_branch)
        after_merge_branch { Changes.transfer_owner_from_branch(self, name, send(name)) }
      end

      expose_public_methods(name, static_state: static_state)
    end

    def expose_public_methods(name, static_state:)
      if static_state.present?
        define_method("#{name}_file_state") do
          static_state
        end
      else
        define_method("#{name}_file_state") do
          try(:state).presence || DEFAULT_FILE_STATE
        end
      end

      define_method("generate_relation_public_#{name}") do
        _generate_relation_public(name)
      end

      define_method("remove_relation_public_#{name}") do
        _remove_relation_public(name)
      end
    end
  end

  private

  def _generate_relation_public(name)
    file = send(name)
    return unless file

    file.generate_public_file

    dir = ::File.dirname(file.public_path)
    ::Dir.glob("#{dir}/*").each do |f|
      next if ::File.directory?(f)
      next if ::File.basename(f) == file.basename
      ::FileUtils.rm(f)
    end
  end

  def _remove_relation_public(name)
    file = send(name)
    file.remove_public_file if file
  end

  module Changes
    module_function

    def ensure_to_have_relation(item, name)
      return if item.send(name)

      file_id = item.send("#{name}_id")
      return if file_id.blank?

      file = SS::File.where(id: file_id).first
      return if file.blank?

      file = file.becomes_with_model rescue file
      item.send("#{name}=", file)
    end

    def normalize_accepts(accepts)
      return accepts if accepts.blank?

      accepts
        .map { _1.downcase }
        .map { _1.start_with?(".") ? _1 : ".#{_1}" }
    end

    def validate_relation(item, name, presence:, accepts:)
      return if item.send("skip_#{name}_validate_relation")

      file = item.send("in_#{name}") || item.send(name)
      if !file && presence
        item.errors.add("#{name}_id", :blank)
      end
      if file && accepts.present? && item.send("rm_#{name}").to_s != "1"
        filename = ""
        filename = file.filename if file.respond_to?(:filename)
        filename = file.original_filename if file.respond_to?(:original_filename)
        ext = ::File.extname(filename).downcase
        if !accepts.include?(ext)
          item.errors.add("#{name}_id", :unable_to_accept_file, allowed_format_list: accepts.join(" / "))
        end
      end

      if !file.frozen? && file.try(:invalid?)
        SS::Model.copy_errors(file, item)
      end
    end

    def save_relation_changes(item, name, class_name:, default_resizing:)
      cur_file = item.send(name)
      upload_file = item.send("in_#{name}")
      if item.changes["#{name}_id"].present? && (id_was = item.send("#{name}_id_was")).present?
        file_was = SS::File.where(id: id_was).first
        if file_was
          file_was = file_was.becomes_with_model rescue file_was
        end
      end

      if upload_file.present?
        item.run_callbacks("#{name}_save") do
          Changes.upload_and_set_relation(item, name, class_name: class_name, default_resizing: default_resizing)
        end
        Changes.destroy_relation(item, name, cur_file)
        return
      end

      if item.send("rm_#{name}").to_s == "1"
        # destroy
        Changes.destroy_relation(item, name, cur_file)
        Changes.clear_relation(item, name)
        return
      end

      # resize や属性変更が必要なら実施する
      if cur_file
        item.run_callbacks("#{name}_save") do
          cur_file = Changes.clone_relation_if_necessary(item, name, cur_file)
          Changes.update_relation(item, name, cur_file, class_name: class_name, default_resizing: default_resizing)
        end
      end

      if file_was && file_was.id != item.send("#{name}_id")
        Changes.destroy_relation(item, name, file_was)
      end
    end

    def set_relation(item, name, file)
      if file.persisted?
        item.send("#{name}_id=", file.id)
      else
        item.send("#{name}_id=", nil)
      end
      item.send("#{name}=", file)
    end

    def clear_relation(item, name)
      item.send("#{name}_id=", nil)
      item.send("#{name}=", nil)
    end

    def transfer_owner_from_branch(item, name, file)
      return if file.blank?

      branch = item.in_branch
      return if branch.blank? || !SS::File.file_owned?(file, SS::Model.container_of(branch))

      owner_item = SS::Model.container_of(item)
      file.update(owner_item: owner_item)
      branch.send("#{name}=", nil)
    end

    def destroy_relation(item, name, file)
      return if file.blank?

      owner_item = SS::Model.container_of(item)
      if owner_item.respond_to?(:branch?) && owner_item.branch?
        # 差し替えページの場合、差し替え元と共有している可能性がある。共有している場合は削除しないようにする。
        return if !SS::File.file_owned?(file, owner_item) && SS::File.file_owned?(file, owner_item.master)
      end

      file.destroy
    end

    def upload_and_set_relation(item, name, class_name:, default_resizing:)
      upload_file = item.send("in_#{name}")
      owner_item = SS::Model.container_of(item)
      resizing = item.send("in_#{name}_resizing").presence || default_resizing
      cur_user = owner_item.try(:cur_user)

      new_file = class_name.constantize.new
      new_file.site_id = owner_item.site_id if owner_item.respond_to?(:site_id)
      new_file.user_id = cur_user.id if cur_user
      new_file.model ||= begin
        if [ DEFAULT_FILE_CLASS_NAME, "Cms::Line::File" ].include?(class_name)
          owner_item.class.name.underscore
        else
          default_model(class_name)
        end
      end
      new_file.state = item.send("#{name}_file_state")
      new_file.filename = upload_file.original_filename
      new_file.owner_item = owner_item
      new_file.in_file = upload_file
      new_file.resizing = resizing
      new_file.save!

      Changes.set_relation(item, name, new_file)
    end

    def clone_relation_if_necessary(item, name, file)
      owner_item = SS::Model.container_of(item)
      return file if SS::File.file_owned?(file, owner_item)

      # 差し替えページの場合、ファイルの所有者が差し替え元なら、そのままとする
      is_branch = owner_item.try(:branch?)
      return file if is_branch && SS::File.file_owned?(file, owner_item.master)

      # ファイルの所有者が存在している場合、誤って所有者を変更することを防止する目的で、ファイルを複製する
      # ただし、ブランチが所有している場合を除く
      return file unless Cms::Reference::Files::Utils.need_to_clone?(file, owner_item, owner_item.try(:in_branch))

      cur_site = owner_item.cur_site if owner_item.respond_to?(:cur_site)
      cur_site ||= owner_item.site if owner_item.respond_to?(:site)
      cur_site ||= SS.current_site
      cur_site = nil unless cur_site.is_a?(SS::Model::Site)
      cur_user = owner_item.cur_user if owner_item.respond_to?(:cur_user)
      cur_user ||= SS.current_user
      clone_file = SS::File.clone_file(file, cur_site: cur_site, cur_user: cur_user, owner_item: owner_item)
      Changes.set_relation(item, name, clone_file)
      clone_file
    end

    def default_model(class_name)
      class_name.constantize.default_scoping.call.selector["model"]
    end

    def update_relation(item, name, file, class_name:, default_resizing:)
      attributes = {}
      owner_item = SS::Model.container_of(item)
      if owner_item.is_a?(Cms::Model::Node)
        owner_item_type = Cms::Node.new(route: owner_item.route).becomes_with_route(owner_item.route).class.name
        file.owner_item_type = owner_item_type
      end

      return if file.frozen?

      # 差し替えページの場合、ファイルの所有者が差し替え元なら、そのままとする
      is_branch = owner_item.try(:branch?)
      return if is_branch && SS::File.file_owned?(file, owner_item.master)

      if !SS::File.file_owned?(file, owner_item)
        if owner_item_type.present? && owner_item.class.name != owner_item_type
          attributes["owner_item_id"] = owner_item.id
          attributes["owner_item_type"] = owner_item_type
        else
          attributes["owner_item"] = owner_item
          attributes["owner_item_id"] = owner_item.id
          attributes["owner_item_type"] = owner_item.class.name
        end
      end

      item.send("#{name}_file_state").tap do |file_state|
        attributes["state"] = file_state if file.state != file_state
      end

      if class_name == DEFAULT_FILE_CLASS_NAME
        expected_model = (owner_item_type.presence || owner_item.class.name).underscore
      else
        expected_model = default_model(class_name)
      end
      if file.model != expected_model
        attributes["model"] = expected_model
      end

      file.update(attributes) if attributes.present?

      if attributes["model"].present?
        resizing = item.send("in_#{name}_resizing").presence || default_resizing
        if resizing
          file.shrink_image_to(resizing[0].to_i, resizing[1].to_i)
        end
      end
    end
  end
end
