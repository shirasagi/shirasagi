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
    export :thumb_url
    export :image?
  end

  class << self
    def model(model, klass)
      self.models << [ model, klass ]
    end

    def find_model_class(model)
      klass = SS::File.models.find { |k, v| k == model }
      klass = klass[1] if klass
      klass
    end
  end
end
