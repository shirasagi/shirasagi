module SS::Relation::File
  extend ActiveSupport::Concern
  extend SS::Translation

  DEFAULT_FILE_CLASS_NAME = "SS::File".freeze

  module ClassMethods
    def belongs_to_file(name, class_name: nil, required: false, static_state: nil, resizing: nil)
      class_name ||= DEFAULT_FILE_CLASS_NAME

      belongs_to name.to_sym, class_name: class_name.to_s

      attr_accessor "in_#{name}", "rm_#{name}", "in_#{name}_resizing"
      permit_params "#{name}_id", "in_#{name}", "rm_#{name}"
      permit_params "in_#{name}_resizing" => []

      # 処理の失敗しやすさの順でいうと:
      #
      # 1. アップロードファイルの SS::File への保存（ファイルサイズが大きいとタイムアウトや DISK FULL の可能性が高まる）
      # 2. ページの保存（nil になってはいけないフィールドが　nil になっているなど）
      # 3. 属性の変更
      #
      # この順番を意識して、SS::File への保存を before_validation で、属性の変更を before_save や after_save で実行するように
      # ハンドラーを登録していく。
      before_validation if: ->{ send("in_#{name}").present? } do
        _upload_and_set_file(name, default_resizing: resizing, state: static_state)
      end
      if class_name != DEFAULT_FILE_CLASS_NAME
        # SS::File 以外のファイルクラスでは、そのクラス関連のモデルしか DB から読み込めないが、
        # シラサギでは登録時に SS::TempFile のインスタンスを用いる。
        # relation の ID が設定されているにもかかわらず、relation が nil となる。それを防ぐ。
        before_validation { _ensure_to_have_relation(name) }
      end
      before_validation { _clone_relation_if_necessary(name) }
      validate { _validate_relation(name) }
      if required
        validate { _validate_relation_required(name) }
      end
      before_save { _destroy_prev_relation(name) }
      before_save if: ->{ send("in_#{name}").blank? && send("rm_#{name}").to_s == "1" } do
        _destroy_relation(name)
      end
      after_save do
        _update_relation_attributes(name, class_name: class_name, default_resizing: resizing, static_state: static_state)
      end
      after_destroy { _destroy_relation(name) }

      expose_public_methods(name, static_state: static_state)
    end

    def expose_public_methods(name, static_state:)
      define_method("#{name}_file_state") do
        _file_state(name, static_state: static_state)
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

  def _upload_and_set_file(name, default_resizing:, static_state:)
    owner_item = SS::Model.container_of(self)
    resizing = send("in_#{name}_resizing").presence || default_resizing

    # SS::File への登録に成功し、その後、何らかの問題で owner_item の保存に失敗したとしても、
    # ファイルダイアログに表示されることを意図して SS::TempFile として登録する。
    # ファイルダイアログに表示できさえすれば、なんとかゾンビファイルにならなくてすむ。
    file = SS::TempFile.create_from_upload!(send("in_#{name}"), resizing: resizing) do |file|
      file.site_id  = site_id if respond_to?(:site_id)
      file.user_id  = owner_item.cur_user.id if owner_item.respond_to?(:cur_user) && owner_item.cur_user
      file.state    = _file_state(name, static_state: static_state)
      # file の owner_item をセットしない。owner_item は保存に失敗する可能性があるので。
    end

    send("#{name}=", file)
    send("#{name}_id=", file.id) if file.persisted?
  end

  def _ensure_to_have_relation(name)
    return if send(name)

    file_id = send("#{name}_id")
    return if file_id.blank?

    send("#{name}=", SS::File.where(id: file_id).first)
  end

  def _clone_relation_if_necessary(name)
    file = send(name)
    return unless file

    owner_item = SS::Model.container_of(self)
    return if SS::File.file_owned?(file, owner_item)

    # 差し替えページの場合、ファイルの所有者が差し替え元なら、そのままとする
    is_branch = owner_item.try(:branch?)
    return if is_branch && SS::File.file_owned?(file, owner_item.master)

    # ファイルの所有者が存在している場合、誤って所有者を変更することを防止する目的で、ファイルを複製する
    # ただし、ブランチが所有している場合を除く
    return unless Cms::Addon::File::Utils.need_to_clone?(file, owner_item, owner_item.try(:in_branch))

    cur_user = owner_item.cur_user if owner_item.respond_to?(:cur_user)
    clone_file = SS::File.clone_file(file, cur_user: cur_user, owner_item: owner_item)
    send("#{name}=", clone_file)
    send("#{name}_id=", clone_file.id)
  end

  def _validate_relation(name)
    file = send(name)
    return true if !file || file.valid?

    SS::Model.copy_errors(file, self)
    false
  end

  def _validate_relation_required(name)
    file = send(name)
    return if file

    errors.add "#{name}_id", :blank
  end

  def _destroy_prev_relation(name)
    return if changes["#{name}_id"].blank?

    id_was = send("#{name}_id_was")
    return if id_was.blank?

    file = SS::File.where(id: id_was).first
    file.destroy if file
  end

  def _destroy_relation(name)
    file = send(name)

    unset("#{name}_id") rescue nil
    send("#{name}=", nil)

    return if file.blank?

    owner_item = SS::Model.container_of(self)
    if owner_item.respond_to?(:branch?) && owner_item.branch?
      # 差し替えページの場合、差し替え元と共有している可能性がある。共有している場合は削除しないようにする。
      return if !SS::File.file_owned?(file, owner_item) && SS::File.file_owned?(file, owner_item.master)
    end

    file.destroy
  end

  def _file_state(_name, static_state: nil)
    static_state || try(:state).presence || 'public'
  end

  def _update_relation_attributes(name, class_name:, default_resizing:, static_state:)
    file = send(name)
    return if file.blank?

    attributes = {}
    owner_item = SS::Model.container_of(self)
    if _need_to_change_owner_item?(file, owner_item)
      attributes[:owner_item] = owner_item
      attributes[:owner_item_id] = owner_item.id
      attributes[:owner_item_type] = owner_item.class.name
    end

    if respond_to?(:state)
      file_state = _file_state(name, static_state: static_state)
      attributes[:state] = file_state if file.state != file_state
    end

    model = class_name == "SS::File" ? self.class.name.underscore : class_name.underscore
    attributes[:model] = model if file.model != model

    file.update(attributes) if attributes.present?

    if attributes[:model].present?
      resizing = send("in_#{name}_resizing").presence || default_resizing
      if resizing
        file.shrink_image_to(resizing[0].to_i, resizing[1].to_i)
      end
    end
  end

  def _need_to_change_owner_item?(file, owner_item)
    return false if SS::File.file_owned?(file, owner_item)

    # 差し替えページの場合、所有者を差し替え元のままとする
    return false if try(:branch?) && SS::File.file_owned?(file, owner_item.master)

    true
  end

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
end
