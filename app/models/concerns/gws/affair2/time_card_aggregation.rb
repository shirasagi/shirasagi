module Gws::Affair2::TimeCardAggregation
  extend ActiveSupport::Concern
  include SS::Permission

  included do
    has_one :aggregation_month, class_name: "Gws::Affair2::Aggregation::Month", dependent: :destroy
  end
end
