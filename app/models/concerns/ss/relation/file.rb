module SS::Relation::File
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    def belongs_to_file(name, opts = {})
      store = opts[:store_as] || "#{name.to_s.singularize}_id"
      belongs_to name, foreign_key: store, class_name: "SS::File", dependent: :destroy

      attr_accessor "in_#{name}", "rm_#{name}"
      permit_params "in_#{name}", "rm_#{name}"

      before_save "validate_relation_#{name}", if: ->{ send("in_#{name}").present? }
      before_save "save_relation_#{name}", if: ->{ send("in_#{name}").present? }
      before_save "remove_relation_#{name}", if: ->{ send("rm_#{name}").to_s == "1" }

      define_method("relation_file") do |name|
        file = send(name) || SS::File.new
        file.in_file  = send("in_#{name}")
        file.filename = file.in_file.original_filename
        file.model    = self.class.to_s.underscore
        file.site_id  = site_id if respond_to?(:site_id)
        file
      end

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
        ss_file = send(name)
        ss_file.destroy if ss_file
        send("#{store}=", nil) rescue nil
      end
    end
  end
end
