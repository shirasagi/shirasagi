module SS::Relation::File
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    def belongs_to_file(name, opts = {})
      store = opts[:store_as] || "#{name.to_s.singularize}_id"
      class_name = opts[:class_name] || "SS::File"

      belongs_to name, foreign_key: store, class_name: class_name, dependent: :destroy

      attr_accessor "in_#{name}", "rm_#{name}"
      permit_params "in_#{name}", "rm_#{name}"

      before_save "validate_relation_#{name}", if: ->{ send("in_#{name}").present? }
      before_save "save_relation_#{name}", if: ->{ send("in_#{name}").present? }
      before_save "remove_relation_#{name}", if: ->{ send("rm_#{name}").to_s == "1" }
      after_save "update_relation_#{name}_state", if: ->{ send(name).present? }

      define_method("validate_relation_#{name}") do
        file = relation_file(name)
        return true if file.valid?

        file.errors.full_messages.each do |msg|
          errors.add :base, msg
        end
        false
      end

      define_method("save_relation_#{name}") do
        file = relation_file(name)
        file.save
        send("#{store}=", file.id)
      end

      define_method("remove_relation_#{name}") do
        file = send(name)
        file.destroy if file
        unset(store) rescue nil
      end

      define_method("update_relation_#{name}_state") do
        return unless respond_to?(:state)
        file = send(name)
        file.update_attributes(state: state) if file.state != state
      end

      define_method("generate_relation_public_#{name}") do
        file = send(name)
        file.generate_public_file if file
      end

      define_method("remove_relation_public_#{name}") do
        file = send(name)
        file.remove_public_file if file
      end
    end
  end

  def relation_file(name)
    file = send(name) || SS::File.new
    file.in_file  = send("in_#{name}")
    file.filename = file.in_file.original_filename
    #file.model    = class_name.underscore
    file.model    = self.class.to_s.underscore
    file.site_id  = site_id if respond_to?(:site_id)
    file.user_id  = @cur_user.id if @cur_user
    file.state    = respond_to?(:state) ? state : "public"
    file
  end
end
