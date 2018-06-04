module SS::Relation::File
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    def belongs_to_file(name, opts = {})
      store = opts[:store_as] || "#{name.to_s.singularize}_id"
      class_name = opts[:class_name] || "SS::File"

      belongs_to name.to_sym, foreign_key: store, class_name: class_name, dependent: :destroy

      attr_accessor "in_#{name}", "rm_#{name}", "in_#{name}_resizing"
      permit_params "in_#{name}", "rm_#{name}"
      permit_params "in_#{name}_resizing" => []

      before_save "validate_relation_#{name}".to_sym, if: ->{ send("in_#{name}").present? }
      before_save "save_relation_#{name}".to_sym, if: ->{ send("in_#{name}").present? }
      before_save "remove_relation_#{name}".to_sym, if: ->{ send("rm_#{name}").to_s == "1" }
      after_save "update_relation_#{name}_state".to_sym, if: ->{ send(name).present? }

      define_method("validate_relation_#{name}") do
        file = relation_file(name, opts)
        return true if file.valid?

        file.errors.full_messages.each do |msg|
          errors.add :base, msg
        end
        false
      end

      define_method("save_relation_#{name}") do
        file = relation_file(name, opts)
        file.save
        send("#{store}=", file.id)
      end

      define_method("remove_relation_#{name}") do
        file = send(name)
        file.destroy if file
        unset(store) rescue nil
        send("#{store}=", nil)
      end

      define_method("#{name}_file_state") do
        opts[:static_state].presence || try(:state).presence || 'public'
      end

      define_method("update_relation_#{name}_state") do
        return unless respond_to?(:state)
        file = send(name)
        file_state = send("#{name}_file_state")
        file.update_attributes(state: file_state) if file.state != file_state
      end

      define_method("generate_relation_public_#{name}") do
        file = send(name)
        return unless file
        file.generate_public_file

        dir = ::File.dirname(file.public_path)
        Dir.glob("#{dir}/*").each do |f|
          next if ::File.directory?(f)
          next if ::File.basename(f) == file.basename
          ::FileUtils.rm(f)
        end
      end

      define_method("remove_relation_public_#{name}") do
        file = send(name)
        file.remove_public_file if file
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
    file.resizing = send("in_#{name}_resizing").presence || opts[:resizing]
    file
  end
end
