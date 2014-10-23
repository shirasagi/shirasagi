module SS::Relation::File
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    def belongs_to_file(name, opts = {})
      store = opts[:store_as] || "#{name.to_s.singularize}_id"
      belongs_to name, foreign_key: store, class_name: "SS::File", dependent: :destroy

      attr_accessor "in_#{name}"
      permit_params "in_#{name}"

      before_save "save_#{name}", if: ->{ send("in_#{name}").present? }

      define_method("save_#{name}") {
        file = send("in_#{name}")

        ss_file = SS::File.new
        ss_file.in_file = file
        ss_file.model = self.class.to_s.underscore
        ss_file.filename = file.original_filename
        ss_file.save

        send("#{store}=", ss_file.id)
      }
    end
  end
end
