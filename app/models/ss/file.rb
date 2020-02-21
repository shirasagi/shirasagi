class SS::File
  include SS::Model::File
  include SS::Relation::Thumb
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
      thumb ? thumb.url : nil
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
  end
end
