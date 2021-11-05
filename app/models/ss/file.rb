class SS::File
  include SS::Model::File
  # include SS::Relation::Thumb
  include SS::Relation::FileHistory
  include SS::Liquidization

  cattr_accessor(:models, instance_accessor: false) { [] }

  liquidize do
    export :name
    export :extname
    export :size
    export :humanized_name
    export :filename
    export :basename
    export :url
    export as: :thumb_url do
      thumb ? thumb_url : nil
    end
    export :image?
  end

  class << self
    def model(model, klass, metadata = {})
      self.models << [ model, klass, metadata ]
    end

    def find_model_class(model)
      config = SS::File.models.find { |k, v| k == model }
      klass = config[1] if config
      klass
    end

    def find_model_metadata(model)
      config = SS::File.models.find { |k, v| k == model }
      metadata = config[2] if config
      metadata
    end

    def clone_file(file, cur_user: nil, owner_item: nil, &block)
      attributes = Hash[file.attributes]
      attributes.stringify_keys!
      attributes.select! { |k| file.fields.key?(k) }

      attributes["user_id"] = cur_user.try(:id) if attributes.key?("user_id")
      if owner_item
        attributes["owner_item_type"] = owner_item.class.name
        attributes["owner_item_id"] = owner_item.id
      else
        attributes["owner_item_type"] = nil
        attributes["owner_item_id"] = nil
      end
      attributes.delete("_id")

      file.class.create_empty!(attributes, validate: false) do |new_file|
        new_file.owner_item = owner_item
        ::FileUtils.copy(file.path, new_file.path)

        yield new_file if block_given?
        new_file.sanitizer_copy_file
      end
    end

    def each_file(file_ids, &block)
      file_ids.each_slice(20) do |ids|
        SS::File.in(id: ids).to_a.map(&:becomes_with_model).each(&block)
      end
    end

    # check file owner without any database accesses
    def file_owned?(file, item)
      file.owner_item_type == item.class.name && file.owner_item_id == item.id
    end
  end
end
