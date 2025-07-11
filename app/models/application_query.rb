class ApplicationQuery
  include ActiveModel::Model

  attr_accessor :model, :base_criteria

  class << self
    def call(model, base_criteria, *args, **options)
      options = args.extract_options! if options.blank?

      query_object = self.new(*args, model: model, base_criteria: base_criteria, **options)
      return base_criteria.none if query_object.invalid?

      query_object.query || base_criteria
    end
  end

  def query
    raise NotImplementedError, "You need to implement #query method which returns Mongoid::Criteria object"
  end

  private

  def none
    @none ||= self.base_criteria.none
  end
end
