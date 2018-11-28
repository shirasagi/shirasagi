class SS::LinkFile
  include SS::Model::LinkFile
  include SS::Relation::Thumb

  cattr_accessor(:models, instance_accessor: false) { [] }

  class << self
    def model(model, klass)
      self.models << [ model, klass ]
    end

    def find_model_class(model)
      klass = SS::LinkFile.models.find { |k, v| k == model }
      klass = klass[1] if klass
      klass
    end
  end
end
