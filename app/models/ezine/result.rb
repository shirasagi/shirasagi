class Ezine::Result
  include Mongoid::Document

  field :started, type: DateTime
  field :delivered, type: DateTime
  field :count, type: Integer

  embedded_in :page, inverse_of: :results
end
