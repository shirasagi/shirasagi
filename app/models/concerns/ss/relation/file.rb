# coding: utf-8
module SS::Relation::File
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    def belongs_to_file(name, opts = {})
      store = opts[:store_as] || "#{name.to_s.singularize}_id"
      field store, type: (opts[:type] || BSON::ObjectId)

      attr_accessor "in_#{name}"
      permit_params "in_#{name}"

      define_method(name) {
        Mongoid::GridFs.find _id: send(store)
      }

      before_save "save_#{name}", if: ->{ send("in_#{name}").present? }
      define_method("save_#{name}") {
        file = send("in_#{name}")
        if file_id = send(store)
          Mongoid::GridFs.delete(file_id) rescue nil
          fs = Mongoid::GridFs.put file, filename: file.original_filename, _id: file_id
        else
          fs = Mongoid::GridFs.put file, filename: file.original_filename
          send("#{store}=", fs.id)
        end
      }

      before_destroy "remove_#{name}", if: ->{ send(store).present? }
      define_method("remove_#{name}") {
        Mongoid::GridFs.delete send(store) rescue nil
      }
    end
  end
end
