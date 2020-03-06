module SS::Relation::File
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    def belongs_to_file(name, opts = {})
      class_name = opts[:class_name].presence || "SS::File"
      required = opts[:required] || false

      belongs_to name.to_sym, class_name: class_name, dependent: :destroy

      attr_accessor "in_#{name}", "rm_#{name}", "in_#{name}_resizing"
      permit_params "in_#{name}", "rm_#{name}"
      permit_params "in_#{name}_resizing" => []

      validate if: ->{ send("in_#{name}").present? } do
        _validate_relation(name, opts)
      end
      validate if: ->{ required } do
        _validate_relation_required(name, opts)
      end
      before_save if: ->{ send("in_#{name}").present? } do
        _save_relation(name, opts)
      end
      before_save if: ->{ send("rm_#{name}").to_s == "1" } do
        _remove_relation(name, opts)
      end
      after_save if: ->{ send(name).present? } do
        _update_relation_state(name, opts)
      end
      after_save if: ->{ send(name).present? } do
        _update_relation_owner_item(name, opts)
      end

      expose_public_methods(name, opts)
    end

    def belongs_to_file2(name, opts = {})
      class_name = opts[:class_name].presence || "SS::File"

      belongs_to name.to_sym, class_name: class_name, dependent: :destroy

      attr_accessor "rm_#{name}", "in_#{name}_resizing"
      permit_params "#{name}_id", "rm_#{name}", "in_#{name}_resizing" => []

      before_save if: ->{ send("#{name}_id").present? } do
        _transfer_relation_ownership(name, opts)
      end
      after_save if: ->{ send(name).present? } do
        _update_relation_state(name, opts)
      end
      after_save if: ->{ send(name).present? } do
        _update_relation_owner_item(name, opts)
      end
      before_save if: ->{ send("rm_#{name}").to_s == "1" } do
        _remove_relation(name, opts)
      end

      expose_public_methods(name, opts)
    end

    def expose_public_methods(name, opts)
      define_method("#{name}_file_state") do
        _file_state(name, opts)
      end

      define_method("generate_relation_public_#{name}") do
        _generate_relation_public(name, opts)
      end

      define_method("remove_relation_public_#{name}") do
        _remove_relation_public(name, opts)
      end
    end
  end

  def relation_file(name, opts = {})
    class_name = opts[:class_name] || "SS::File"

    file = send(name) || class_name.constantize.new
    file.in_file  = send("in_#{name}")
    file.filename = file.in_file.original_filename
    # file.model    = class_name.underscore
    file.model    = self.class.to_s.underscore
    file.site_id  = site_id if respond_to?(:site_id)
    file.user_id  = @cur_user.id if @cur_user
    file.state    = send("#{name}_file_state")
    file.content_type = ::Fs.content_type(file.filename)
    file.resizing = send("in_#{name}_resizing").presence || opts[:resizing]
    file.owner_item = self.embedded? ? self._parent : self if file.respond_to?(:owner_item=)
    file
  end

  private

  def _validate_relation(name, opts)
    file = relation_file(name, opts)
    return true if file.valid?

    file.errors.full_messages.each do |msg|
      errors.add :base, msg
    end

    false
  end

  def _validate_relation_required(name, _opts)
    return if send("in_#{name}").present?
    return if send(name)
    errors.add "#{name}_id", :blank
  end

  def _save_relation(name, opts)
    file = relation_file(name, opts)
    file.save
    send("#{name}=", file)
  end

  def _remove_relation(name, _opts)
    file = send(name)
    file.destroy if file
    unset("#{name}_id") rescue nil
    send("#{name}=", nil)
  end

  def _file_state(_name, opts)
    opts[:static_state].presence || try(:state).presence || 'public'
  end

  def _update_relation_state(name, _opts)
    return unless respond_to?(:state)

    file = send(name)
    file_state = send("#{name}_file_state")
    file.update(state: file_state) if file.state != file_state
  end

  def _update_relation_owner_item(name, _opts)
    file = send(name)
    owner_item = self.embedded? ? self._parent : self
    if file.owner_item.blank? || file.owner_item_type != owner_item.class.name || file.owner_item_id != owner_item.id
      file.update(owner_item: owner_item)
    end
  end

  def _generate_relation_public(name, _opts)
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

  def _remove_relation_public(name, opts)
    file = send(name)
    file.remove_public_file if file
  end

  def _transfer_relation_ownership(name, opts)
    return unless send("#{name}_id_changed?")

    cur_id = send("#{name}_id")
    prev_id = send("#{name}_id_was")

    file = SS::File.find(cur_id)
    expected_model = opts[:file_model] || (opts[:class_name].presence || "SS::File").to_s.underscore
    if file.model != expected_model
      file.update(model: expected_model)

      resizing = send("in_#{name}_resizing").presence || opts[:resizing]
      if resizing
        file.shrink_image_to(resizing[0].to_i, resizing[1].to_i)
      end
    end

    if prev_id.present?
      SS::File.where(id: prev_id).destroy_all
    end

    true
  end
end
